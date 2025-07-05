import {
  ExecutionContext,
  InternalServerErrorException,
  createParamDecorator,
} from '@nestjs/common';
import { UserRequest } from '../interfaces';

export const getUserFromRequestFn = (_params: any, ctx: ExecutionContext) => {
  const user = ctx.switchToHttp().getRequest<{ user: UserRequest }>().user;

  if (!user) {
    throw new InternalServerErrorException('User not found (Decorator error)');
  }

  return user;
};

export const GetUser = createParamDecorator(getUserFromRequestFn);
