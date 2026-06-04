module users

pub struct CreateUserRequest {
pub:
	name  string
	email string
}

pub struct CreateUserResponse {
pub:
	id    string
	name  string
	email string
}

pub struct GetUserRequest {
pub:
	id string
}

pub struct GetUserResponse {
pub:
	id    string
	name  string
	email string
}

pub struct ListUsersRequest {
pub:
	limit  int
	cursor string
}

pub struct ListUsersResponse {
pub:
	users       []UserSummary
	next_cursor string
}

pub struct UserSummary {
pub:
	id    string
	name  string
	email string
}
