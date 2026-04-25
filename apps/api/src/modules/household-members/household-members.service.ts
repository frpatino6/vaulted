import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateHouseholdMemberDto } from './dto/create-household-member.dto';
import { UpdateHouseholdMemberDto } from './dto/update-household-member.dto';
import {
  HouseholdMember,
  HouseholdMemberDocument,
} from './schemas/household-member.schema';

@Injectable()
export class HouseholdMembersService {
  constructor(
    @InjectModel(HouseholdMember.name)
    private readonly householdMemberModel: Model<HouseholdMemberDocument>,
  ) {}

  async create(
    tenantId: string,
    userId: string,
    dto: CreateHouseholdMemberDto,
  ): Promise<HouseholdMember> {
    return this.householdMemberModel.create({
      tenantId,
      name: dto.name,
      relationship: dto.relationship,
      isMinor: dto.isMinor ?? false,
      linkedUserId: dto.linkedUserId ?? null,
      notes: dto.notes,
      isActive: true,
      createdBy: userId,
    });
  }

  async findAll(tenantId: string, includeInactive: boolean): Promise<HouseholdMember[]> {
    return this.householdMemberModel
      .find({
        tenantId,
        ...(includeInactive ? {} : { isActive: true }),
      })
      .sort({ name: 1 })
      .exec();
  }

  async update(
    tenantId: string,
    memberId: string,
    dto: UpdateHouseholdMemberDto,
  ): Promise<HouseholdMember> {
    const member = await this.householdMemberModel
      .findOneAndUpdate(
        { _id: memberId, tenantId },
        {
          $set: {
            ...(dto.name !== undefined ? { name: dto.name } : {}),
            ...(dto.relationship !== undefined
              ? { relationship: dto.relationship }
              : {}),
            ...(dto.isMinor !== undefined ? { isMinor: dto.isMinor } : {}),
            ...(dto.linkedUserId !== undefined
              ? { linkedUserId: dto.linkedUserId || null }
              : {}),
            ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
            ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!member) {
      throw new NotFoundException('Household member not found');
    }

    return member;
  }

  async archive(tenantId: string, memberId: string): Promise<{ archived: true }> {
    const result = await this.householdMemberModel
      .updateOne(
        { _id: memberId, tenantId },
        {
          $set: {
            isActive: false,
          },
        },
      )
      .exec();

    if (result.matchedCount === 0) {
      throw new NotFoundException('Household member not found');
    }

    return { archived: true };
  }
}
