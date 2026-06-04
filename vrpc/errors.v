module vrpc

import json

pub struct ValidationError {
pub:
	field   string
	rule    string
	message string
}

pub struct ApiError {
pub:
	code    string
	message string
	details []ValidationError
}

pub struct ValidationErrorResponse {
pub:
	error ApiError
}

pub struct FrameworkError {
pub:
	msg_text string
	err_code string
	status   int
}

pub fn (e FrameworkError) msg() string {
	return e.msg_text
}

pub fn (e FrameworkError) code() int {
	return e.status
}

pub fn bad_request(message string) FrameworkError {
	return FrameworkError{ msg_text: message, err_code: 'bad_request', status: 400 }
}

pub fn unauthorized(message string) FrameworkError {
	return FrameworkError{ msg_text: message, err_code: 'unauthorized', status: 401 }
}

pub fn forbidden(message string) FrameworkError {
	return FrameworkError{ msg_text: message, err_code: 'forbidden', status: 403 }
}

pub fn not_found(message string) FrameworkError {
	return FrameworkError{ msg_text: message, err_code: 'not_found', status: 404 }
}

pub fn conflict(message string) FrameworkError {
	return FrameworkError{ msg_text: message, err_code: 'conflict', status: 409 }
}

pub fn internal(message string) FrameworkError {
	return FrameworkError{ msg_text: message, err_code: 'internal', status: 500 }
}

pub fn validation_error_response(details []ValidationError) Response {
	body := json.encode(ValidationErrorResponse{
		error: ApiError{
			code:    'validation_failed'
			message: 'Request validation failed'
			details: details
		}
	})
	return Response{
		status: 400
		body:   body
		headers: {
			'Content-Type': 'application/json'
		}
	}
}

pub fn error_to_response(err IError) Response {
	status := if err.code() > 0 { err.code() } else { 500 }
	body := json.encode(ApiError{
		code:    'error'
		message: err.msg()
	})
	return Response{
		status: status
		body:   body
		headers: {
			'Content-Type': 'application/json'
		}
	}
}
