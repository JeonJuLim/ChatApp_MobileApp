// friends/dto/friend-relation.dto.ts
export class FriendRelationDto {
  id: string;       // id user
  username: string;
  fullName: string;
  avatarUrl?: string;
  status: 'friend' | 'incomingRequest' | 'outgoingRequest';
}
