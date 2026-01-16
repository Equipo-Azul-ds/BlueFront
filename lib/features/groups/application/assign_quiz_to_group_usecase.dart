import 'package:uuid/uuid.dart';

import '../domain/entities/GroupQuizAssignment.dart';
import '../domain/repositories/GroupRepository.dart';
import '../domain/services/quiz_read_service.dart';
import '../domain/entities/Group.dart';

class AssignQuizToGroupInput {
  final String groupId;
  final String quizId;
  final String currentUserId;
  final DateTime availableUntil;
  final DateTime? now;

  AssignQuizToGroupInput({
    required this.groupId,
    required this.quizId,
    required this.currentUserId,
    required this.availableUntil,
    this.now,
  });
}

class AssignQuizToGroupOutput {
  final String id;
  final String groupId;
  final String quizId;
  final String assignedBy;
  final String createdAt;
  final String availableFrom;
  final String availableUntil;
  final bool isActive;

  AssignQuizToGroupOutput({
    required this.id,
    required this.groupId,
    required this.quizId,
    required this.assignedBy,
    required this.createdAt,
    required this.availableFrom,
    required this.availableUntil,
    required this.isActive,
  });
}

class AssignQuizToGroupUseCase {
  final GroupRepository groupRepository;
  final QuizReadService quizReadService;

  AssignQuizToGroupUseCase({
    required this.groupRepository,
    required this.quizReadService,
  });

  Future<AssignQuizToGroupOutput> execute(AssignQuizToGroupInput input) async {
    final now = input.now ?? DateTime.now();
    final availableFrom = now;
    final availableUntil = input.availableUntil;

    final group = await groupRepository.findById(input.groupId);
    if (group == null) {
      throw Exception('Group with id ${input.groupId} not found');
    }

    if (!group.isMember(input.currentUserId)) {
      throw Exception('User ${input.currentUserId} is not a member of the group');
    }

    final canUseQuiz = await quizReadService.quizBelongsToUser(
      quizId: input.quizId,
      userId: input.currentUserId,
    );
    if (!canUseQuiz) {
      throw Exception('El quiz no existe o no pertenece al usuario');
    }

    final assignment = GroupQuizAssignment(
      id: const Uuid().v4(),
      groupId: group.id,
      quizId: input.quizId,
      assignedBy: input.currentUserId,
      createdAt: now,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      isActive: true,
    );

    final updatedGroup = group.addAssignment(assignment, now);
    await groupRepository.save(updatedGroup);

    return AssignQuizToGroupOutput(
      id: assignment.id,
      groupId: assignment.groupId,
      quizId: assignment.quizId,
      assignedBy: assignment.assignedBy,
      createdAt: assignment.createdAt.toIso8601String(),
      availableFrom: assignment.availableFrom.toIso8601String(),
      availableUntil: assignment.availableUntil.toIso8601String(),
      isActive: assignment.isActive,
    );
  }
}
