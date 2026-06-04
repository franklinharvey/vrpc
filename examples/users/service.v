module users

import vrpc

pub struct UserServiceImpl {
pub mut:
	repo MemoryRepo
}

pub fn new_service(repo MemoryRepo) UserServiceImpl {
	return UserServiceImpl{
		repo: repo
	}
}

pub fn (mut s UserServiceImpl) create_user(req CreateUserRequest) !CreateUserResponse {
	user := s.repo.create(req.name, req.email)!
	return CreateUserResponse{
		id:    user.id
		name:  user.name
		email: user.email
	}
}

pub fn (s UserServiceImpl) get_user(req GetUserRequest) !GetUserResponse {
	user := s.repo.find_by_id(req.id) or {
		return vrpc.not_found('User not found')
	}
	return GetUserResponse{
		id:    user.id
		name:  user.name
		email: user.email
	}
}

pub fn (s UserServiceImpl) list_users(req ListUsersRequest) !ListUsersResponse {
	mut limit := req.limit
	if limit <= 0 {
		limit = 20
	}
	page := s.repo.list(limit, req.cursor)!
	return ListUsersResponse{
		users: page.users.map(UserSummary{
			id:    it.id
			name:  it.name
			email: it.email
		})
		next_cursor: page.next_cursor
	}
}
