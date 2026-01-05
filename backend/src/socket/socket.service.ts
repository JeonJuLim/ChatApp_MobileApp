import { Injectable } from '@nestjs/common';
import { Socket } from 'socket.io';
import { PrismaService } from '../database/prisma.service';

type CallSession = {
  callId: string;
  conversationId: string;
  fromUserId: string;
  toUserId: string;
  type: 'audio' | 'video';
  startedAt: number; // ms
  acceptedAt?: number; // ms
  timeoutHandle?: NodeJS.Timeout;
};

@Injectable()
export class SocketService {
  constructor(private readonly prisma: PrismaService) {}

  // In-memory call sessions (MVP). Nếu deploy multi-instance => dùng Redis.
  private readonly callSessions = new Map<string, CallSession>();

  // ring timeout (không bắt máy) - chỉnh tùy ý
  private readonly RING_TIMEOUT_MS = 30_000;

  async joinConversation(client: Socket, data: { conversationId: string; userId: string }) {
    client.join(data.conversationId);
    client.emit('joined_conversation', { ok: true, conversationId: data.conversationId });
    return { ok: true };
  }

  // ✅ SEND MESSAGE -> save DB + emit new_message
  async sendMessage(
    client: Socket,
    data: { conversationId: string; senderId: string; content: string; type?: string },
  ) {
    const msg = await this.prisma.message.create({
      data: {
        conversationId: data.conversationId,
        senderId: data.senderId,
        content: data.content,
        type: data.type ?? 'text',
      },
      select: {
        id: true,
        content: true,
        type: true,
        createdAt: true,
        senderId: true,
        conversationId: true,
      },
    });

    client.to(data.conversationId).emit('new_message', msg);
    client.emit('new_message', msg);

    return { ok: true, message: msg };
  }

  // =========================
  // ✅ TYPING
  // =========================
  async typingStart(client: Socket, data: { conversationId: string; userId: string }) {
    client.to(data.conversationId).emit('typing', {
      conversationId: data.conversationId,
      userId: data.userId,
      isTyping: true,
    });
    return { ok: true };
  }

  async typingStop(client: Socket, data: { conversationId: string; userId: string }) {
    client.to(data.conversationId).emit('typing', {
      conversationId: data.conversationId,
      userId: data.userId,
      isTyping: false,
    });
    return { ok: true };
  }

  // =========================
  // ✅ DELIVERED / SEEN
  // =========================
  async messageDelivered(
    client: Socket,
    data: { conversationId: string; userId: string; messageId: string },
  ) {
    await this.prisma.messageStatus.upsert({
      where: {
        messageId_userId: { messageId: data.messageId, userId: data.userId },
      },
      update: { status: 'delivered' },
      create: { messageId: data.messageId, userId: data.userId, status: 'delivered' },
    });

    client.to(data.conversationId).emit('message_status', {
      messageId: data.messageId,
      userId: data.userId,
      status: 'delivered',
    });

    return { ok: true };
  }

  async messageSeen(client: Socket, data: { conversationId: string; userId: string; messageId: string }) {
    await this.prisma.messageStatus.upsert({
      where: {
        messageId_userId: { messageId: data.messageId, userId: data.userId },
      },
      update: { status: 'seen' },
      create: { messageId: data.messageId, userId: data.userId, status: 'seen' },
    });

    client.to(data.conversationId).emit('message_status', {
      messageId: data.messageId,
      userId: data.userId,
      status: 'seen',
    });

    return { ok: true };
  }

  // ==========================================================
  // ✅ CALL CONTROL (UI state + CallLog)
  // ==========================================================

  /**
   * Emit chung cho room:
   * event: call:status
   * payload: { callId, status, ... }
   */
  private emitCallStatus(conversationId: string, payload: any, client?: Socket) {
    // broadcast cho người khác trong room
    if (client) client.to(conversationId).emit('call:status', payload);
    // đảm bảo sender cũng nhận
    if (client) client.emit('call:status', payload);
  }

  private clearCallTimeout(callId: string) {
    const s = this.callSessions.get(callId);
    if (s?.timeoutHandle) clearTimeout(s.timeoutHandle);
  }

  async callStart(
    client: Socket,
    payload: {
      callId: string;
      conversationId: string;
      fromUserId: string;
      toUserId: string;
      type: 'audio' | 'video';
    },
  ) {
    // 1) tạo session in-memory
    const session: CallSession = {
      callId: payload.callId,
      conversationId: payload.conversationId,
      fromUserId: payload.fromUserId,
      toUserId: payload.toUserId,
      type: payload.type,
      startedAt: Date.now(),
    };

    // 2) set timeout: quá 30s chưa accept -> no_answer
    session.timeoutHandle = setTimeout(async () => {
      const s = this.callSessions.get(payload.callId);
      if (!s) return;
      // nếu chưa accepted thì coi như no_answer
      if (!s.acceptedAt) {
        // update DB: vẫn là missed (hoặc bạn set status='missed')
        await this.safeUpdateCallLog(payload.callId, { status: 'missed' });

        // caller nhận no_answer
        // do server không có "client", ta broadcast room
        // room có cả A và B nếu cả 2 join_conversation; caller vẫn nhận được
        // Nếu B không join room thì caller vẫn nhận (đang join)
        // => broadcast room là đủ
        // payload status
        // note: gửi cho cả room, Flutter của B có thể tự đóng nếu đang incoming
        // (hoặc ignore)
        // dùng server-side emit qua room:
        client.nsp.to(payload.conversationId).emit('call:status', {
          callId: payload.callId,
          status: 'no_answer',
        });

        this.callSessions.delete(payload.callId);
      }
    }, this.RING_TIMEOUT_MS);

    this.callSessions.set(payload.callId, session);

    // 3) create CallLog ngay từ đầu: status = missed
    // dùng callId làm id để khỏi thêm cột
    await this.prisma.callLog.create({
      data: {
        id: payload.callId,
        type: payload.type,
        status: 'missed',
        duration: null,
        callerId: payload.fromUserId,
        receiverId: payload.toUserId,
        conversationId: payload.conversationId,
      },
    });

    // 4) notify room: ringing
    this.emitCallStatus(
      payload.conversationId,
      {
        callId: payload.callId,
        status: 'ringing',
        fromUserId: payload.fromUserId,
        toUserId: payload.toUserId,
        type: payload.type,
      },
      client,
    );

    // 5) incoming event cho B (để mở màn accept/reject)
    // broadcast room: user khác trong room sẽ nhận
    client.to(payload.conversationId).emit('call:incoming', {
      callId: payload.callId,
      conversationId: payload.conversationId,
      fromUserId: payload.fromUserId,
      toUserId: payload.toUserId,
      type: payload.type,
    });

    return { ok: true };
  }

  async callAccept(
    client: Socket,
    payload: { callId: string; conversationId: string; fromUserId: string; toUserId: string },
  ) {
    const s = this.callSessions.get(payload.callId);
    if (!s) {
      // session mất (timeout hoặc restart) => báo ended
      this.emitCallStatus(payload.conversationId, { callId: payload.callId, status: 'ended' }, client);
      return { ok: false, message: 'call session not found' };
    }

    s.acceptedAt = Date.now();
    this.callSessions.set(payload.callId, s);
    this.clearCallTimeout(payload.callId);

    // DB: accepted
    await this.safeUpdateCallLog(payload.callId, { status: 'accepted' });

    // notify room: accepted -> Flutter chuyển timer 00:00
    this.emitCallStatus(payload.conversationId, { callId: payload.callId, status: 'accepted' }, client);

    return { ok: true };
  }

  async callReject(
    client: Socket,
    payload: { callId: string; conversationId: string; fromUserId: string; toUserId: string },
  ) {
    // reject => caller coi như no_answer (UI bạn yêu cầu)
    this.clearCallTimeout(payload.callId);
    this.callSessions.delete(payload.callId);

    // DB: rejected (nếu bạn muốn phân biệt). Nếu không, giữ missed.
    await this.safeUpdateCallLog(payload.callId, { status: 'rejected' });

    // caller UI: "người nhận không bắt máy"
    this.emitCallStatus(payload.conversationId, { callId: payload.callId, status: 'no_answer' }, client);

    // callee UI: ended (đóng màn)
    client.to(payload.conversationId).emit('call:status', { callId: payload.callId, status: 'ended' });
    client.emit('call:status', { callId: payload.callId, status: 'ended' });

    return { ok: true };
  }

  async callEnd(
    client: Socket,
    payload: {
      callId: string;
      conversationId: string;
      fromUserId: string;
      toUserId: string;
      duration?: number;
    },
  ) {
    const s = this.callSessions.get(payload.callId);
    this.clearCallTimeout(payload.callId);
    this.callSessions.delete(payload.callId);

    // duration ưu tiên client gửi; nếu không có thì tính từ acceptedAt
    let durationSec: number | null = null;
    if (typeof payload.duration === 'number') {
      durationSec = payload.duration;
    } else if (s?.acceptedAt) {
      durationSec = Math.max(0, Math.floor((Date.now() - s.acceptedAt) / 1000));
    }

    await this.safeUpdateCallLog(payload.callId, {
      status: 'ended',
      duration: durationSec,
    });

    // notify room: ended
    this.emitCallStatus(payload.conversationId, { callId: payload.callId, status: 'ended', duration: durationSec }, client);

    // vẫn relay event call:end (nếu client signaling muốn nghe event này)
    client.to(payload.conversationId).emit('call:end', payload);
    client.emit('call:end', payload);

    return { ok: true };
  }

  /**
   * helper update CallLog tránh crash nếu record không tồn tại
   * (ví dụ callId sai)
   */
  private async safeUpdateCallLog(callId: string, data: { status?: string; duration?: number | null }) {
    try {
      await this.prisma.callLog.update({
        where: { id: callId },
        data,
      });
    } catch (e) {
      // MVP: ignore
    }
  }
}
