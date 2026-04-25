import 'household_members_remote_data_source.dart';
import 'models/household_member_model.dart';

class HouseholdMembersRepository {
  HouseholdMembersRepository(this._remote);

  final HouseholdMembersRemoteDataSource _remote;

  Future<List<HouseholdMemberModel>> getMembers() => _remote.getMembers();

  Future<HouseholdMemberModel> createMember({
    required String name,
    String? relationship,
    bool isMinor = false,
  }) => _remote.createMember(
    name: name,
    relationship: relationship,
    isMinor: isMinor,
  );

  Future<void> archiveMember(String id) => _remote.archiveMember(id);
}
