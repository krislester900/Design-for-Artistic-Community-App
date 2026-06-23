import 'package:uuid/uuid.dart';

class CollaborationProject {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String category;
  final List<String> roles;
  final List<String> applicants;
  final Map<String, String> contributors;
  final DateTime createdAt;
  final bool isOpen;

  CollaborationProject({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.category,
    required this.roles,
    this.applicants = const [],
    this.contributors = const {},
    DateTime? createdAt,
    this.isOpen = true,
  }) : createdAt = createdAt ?? DateTime.now();
}

class CollaborationService {
  final List<CollaborationProject> _projects = [];
  final Uuid _uuid = const Uuid();

  List<CollaborationProject> get openProjects => _projects.where((p) => p.isOpen).toList();
  List<CollaborationProject> get allProjects => _projects;

  CollaborationProject createProject({
    required String title,
    required String description,
    required String creatorId,
    required String category,
    required List<String> roles,
  }) {
    final project = CollaborationProject(
      id: _uuid.v4(),
      title: title,
      description: description,
      creatorId: creatorId,
      category: category,
      roles: roles,
    );
    _projects.add(project);
    return project;
  }

  bool applyToProject(String projectId, String userId) {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return false;
    final project = _projects[index];
    if (project.applicants.contains(userId)) return false;
    _projects[index] = CollaborationProject(
      id: project.id,
      title: project.title,
      description: project.description,
      creatorId: project.creatorId,
      category: project.category,
      roles: project.roles,
      applicants: [...project.applicants, userId],
      contributors: project.contributors,
      createdAt: project.createdAt,
      isOpen: project.isOpen,
    );
    return true;
  }

  bool acceptApplicant(String projectId, String userId, String role) {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return false;
    final project = _projects[index];
    _projects[index] = CollaborationProject(
      id: project.id,
      title: project.title,
      description: project.description,
      creatorId: project.creatorId,
      category: project.category,
      roles: project.roles,
      applicants: project.applicants.where((a) => a != userId).toList(),
      contributors: {...project.contributors, userId: role},
      createdAt: project.createdAt,
      isOpen: project.isOpen,
    );
    return true;
  }

  void closeProject(String projectId) {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final project = _projects[index];
      _projects[index] = CollaborationProject(
        id: project.id,
        title: project.title,
        description: project.description,
        creatorId: project.creatorId,
        category: project.category,
        roles: project.roles,
        applicants: project.applicants,
        contributors: project.contributors,
        createdAt: project.createdAt,
        isOpen: false,
      );
    }
  }
}