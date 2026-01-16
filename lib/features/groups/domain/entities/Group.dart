import 'GroupInvitationToken.dart';
import 'GroupMember.dart';
import 'GroupQuizAssignment.dart';
import 'GroupQuizCompletion.dart';
import 'GroupRole.dart';

class Group {
  final String id;
  String name;
  String? description;
  final String adminId;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<GroupMember> members;
  final List<GroupQuizAssignment> quizAssignments;
  final List<GroupQuizCompletion> completions;
  final GroupInvitationToken? invitation;
  
  // Campos para vista resumen (endpoint /groups)
  final int? _memberCountSnapshot;
  final String? _userRoleSnapshot;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.adminId,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
    this.quizAssignments = const [],
    this.completions = const [],
    this.invitation,
    int? memberCountSnapshot,
    String? userRoleSnapshot,
  }) : _memberCountSnapshot = memberCountSnapshot,
       _userRoleSnapshot = userRoleSnapshot;

  bool get hasInvitation => invitation != null;
  
  // Usa el snapshot si existe (vista lista), sino cuenta la lista completa (vista detalle)
  int get memberCount => _memberCountSnapshot ?? members.length;
  
  // Exponer el rol del usuario autenticado si se conoce por snapshot
  String? get currentUserRole => _userRoleSnapshot;

  bool isAdmin(String userId) {
    if (_userRoleSnapshot != null) {
      return _userRoleSnapshot!.toLowerCase() == 'admin';
    }
    return adminId == userId;
  }
  bool isMember(String userId) => members.any((m) => m.userId == userId);

  Group addMember(GroupMember member, DateTime now) {
    if (member.role == GroupRole.admin) {
      // El dominio original no permite agregar admin directamente.
      throw Exception('No se puede agregar un miembro directamente como admin');
    }
    if (isMember(member.userId)) {
      throw Exception('El usuario ya es miembro del grupo');
    }
    final updatedMembers = [...members, member];
    return copyWith(members: updatedMembers, updatedAt: now);
  }

  Group removeMember(String userId, DateTime now) {
    final updatedMembers = members.where((m) => m.userId != userId).toList();
    return copyWith(members: updatedMembers, updatedAt: now);
  }

  Group addAssignment(GroupQuizAssignment assignment, DateTime now) {
    final updatedAssignments = [...quizAssignments, assignment];
    return copyWith(quizAssignments: updatedAssignments, updatedAt: now);
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GroupMember>? members,
    List<GroupQuizAssignment>? quizAssignments,
    List<GroupQuizCompletion>? completions,
    GroupInvitationToken? invitation,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
      quizAssignments: quizAssignments ?? this.quizAssignments,
      completions: completions ?? this.completions,
      invitation: invitation ?? this.invitation,
    );
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    final membersJson = (json['members'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GroupMember.fromJson)
        .toList();

    final assignmentsRaw = json['quizAssignments'] ?? json['assignments'] ?? json['quizzes'] ?? json['groupQuizzes'];
    final assignmentsJson = (assignmentsRaw as List? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(GroupQuizAssignment.fromJson)
      .toList();

    final completionsJson = (json['completions'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GroupQuizCompletion.fromJson)
        .toList();

    final createdRaw = json['createdAt'] ?? json['created_at'];
    final updatedRaw = json['updatedAt'] ?? json['updated_at'] ?? createdRaw;

    GroupInvitationToken? invitation;
    final invitationJson = json['invitation'] ?? json['invitationToken'];
    if (invitationJson is Map<String, dynamic>) {
      invitation = GroupInvitationToken.fromJson(invitationJson);
    }

    // Safely parse memberCount
    int? parsedMemberCount;
    if (json['memberCount'] != null) {
      final v = json['memberCount'];
      if (v is int) parsedMemberCount = v;
      else if (v is String) parsedMemberCount = int.tryParse(v);
    }

    return Group(
      id: json['id'] as String? ?? json['groupId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      adminId: json['adminId'] as String? ?? json['admin_id'] as String? ?? '',
      createdAt: createdRaw is String
          ? DateTime.parse(createdRaw)
          : DateTime.now(),
      updatedAt: updatedRaw is String
          ? DateTime.parse(updatedRaw)
          : DateTime.now(),
      members: membersJson,
      quizAssignments: assignmentsJson,
      completions: completionsJson,
      invitation: invitation,
      memberCountSnapshot: parsedMemberCount,
      userRoleSnapshot: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'quizAssignments': quizAssignments.map((qa) => qa.toJson()).toList(),
      'completions': completions.map((c) => c.toJson()).toList(),
      'invitation': invitation?.toJson(),
    };
  }
}
