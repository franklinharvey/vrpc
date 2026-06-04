module users

pub struct User {
pub:
	id    string
	name  string
	email string
}

pub struct UserPage {
pub:
	users       []User
	next_cursor string
}

pub struct MemoryRepo {
mut:
	users map[string]User
	seq   int
}

pub fn new_memory_repo() MemoryRepo {
	return MemoryRepo{
		users: map[string]User{}
	}
}

pub fn (mut r MemoryRepo) create(name string, email string) !User {
	r.seq++
	id := 'u${r.seq}'
	user := User{
		id:    id
		name:  name
		email: email
	}
	r.users[id] = user
	return user
}

pub fn (r MemoryRepo) find_by_id(id string) !User {
	return r.users[id] or { return error('not found') }
}

pub fn (r MemoryRepo) list(limit int, cursor string) !UserPage {
	mut keys := r.users.keys()
	keys.sort()
	mut start := 0
	if cursor != '' {
		for i, k in keys {
			if k == cursor {
				start = i + 1
				break
			}
		}
	}
	mut lim := limit
	if lim <= 0 {
		lim = 20
	}
	mut end := start + lim
	if end > keys.len {
		end = keys.len
	}
	mut page_users := []User{}
	for k in keys[start..end] {
		page_users << r.users[k]
	}
	mut next := ''
	if end < keys.len && page_users.len > 0 {
		next = page_users[page_users.len - 1].id
	}
	return UserPage{
		users:       page_users
		next_cursor: next
	}
}
