module veetest

pub fn check(ok bool, msg string) ! {
	if !ok {
		return error(msg)
	}
}

pub fn eq_str(label string, want string, got string) ! {
	if want != got {
		return error('${label}: want "${want}", got "${got}"')
	}
}

pub fn eq_int(label string, want int, got int) ! {
	if want != got {
		return error('${label}: want ${want}, got ${got}')
	}
}

pub fn contains(label string, haystack string, needle string) ! {
	if !haystack.contains(needle) {
		return error('${label}: expected to contain "${needle}"')
	}
}

pub fn len_is[T](label string, got []T, want int) ! {
	if got.len != want {
		return error('${label}: want len ${want}, got ${got.len}')
	}
}
