module main

import os

const contract_names = ['contract.v', 'contracts.v']

pub fn find_contract_files(dir string) ![]string {
	mut files := []string{}
	walk_contracts(dir, mut files)!
	return files
}

fn walk_contracts(dir string, mut files []string) ! {
	entries := os.ls(dir) or { return error('cannot list ${dir}') }
	for entry in entries {
		full := os.join_path(dir, entry)
		if os.is_dir(full) {
			if entry == '.git' || entry == 'node_modules' || entry == 'generated' {
				continue
			}
			walk_contracts(full, mut files)!
		} else if entry in contract_names || entry.ends_with('.contract.v') || entry.ends_with('.contract') {
			files << full
		}
	}
}

pub fn parse_contract_file(path string) !Service {
	content := os.read_file(path)!
	lines := content.split_into_lines()
	mut service := Service{
		types:      map[string]TypeDef{}
		procedures: []
	}
	mut in_interface := false
	mut attr_line := ''
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('module ') {
			service.module = trimmed['module '.len..].trim_space()
			continue
		}
		if trimmed.contains('@[service') {
			service.prefix = extract_attr_value(trimmed, 'prefix') or { '/' }
			continue
		}
		if trimmed.contains('interface ') && trimmed.contains('Service') {
			in_interface = true
			service.name = extract_interface_name(trimmed) or { 'Service' }
			continue
		}
		if in_interface {
			if trimmed == '}' {
				in_interface = false
				continue
			}
			if trimmed.starts_with('@[') {
				attr_line = trimmed
				continue
			}
			if attr_line != '' && trimmed.contains('(') && trimmed.contains('!') {
				if proc := parse_procedure_from_lines(attr_line, trimmed) {
					service.procedures << proc
				}
				attr_line = ''
				continue
			}
			if proc := parse_procedure_line(trimmed) {
				service.procedures << proc
			}
		}
		if trimmed.starts_with('pub struct ') {
			if st := parse_struct_block(lines, line) {
				service.types[st.name] = st
			}
		}
	}
	if service.name == '' {
		return error('no @[service] interface found in ${path}')
	}
	return service
}

fn parse_procedure_from_lines(attr_line string, sig_line string) ?Procedure {
	attr_start := attr_line.index('@[') or { return none }
	attr_end := attr_line.index_after(']', attr_start) or { return none }
	attr := attr_line[attr_start + 2..attr_end]
	method, path := parse_http_attr(attr) or { return none }
	return parse_procedure_signature(sig_line, method, path)
}

fn parse_procedure_line(line string) ?Procedure {
	if !line.contains('@[') || !line.contains('(') {
		return none
	}
	attr_start := line.index('@[') or { return none }
	attr_end := line.index_after(']', attr_start) or { return none }
	attr := line[attr_start + 2..attr_end]
	method, path := parse_http_attr(attr) or { return none }
	rest := line[attr_end + 1..].trim_space()
	return parse_procedure_signature(rest, method, path)
}

// attr is like "get: '/:id'" — path may contain ':' so split only on the first colon.
fn parse_http_attr(attr string) ?(HttpMethod, string) {
	colon := attr.index(':') or { return none }
	method_str := attr[..colon].trim_space()
	method := http_method_from_str(method_str) or { return none }
	path := attr[colon + 1..].trim_space().replace("'", '').replace('"', '')
	return method, path
}

fn trim_trailing_paren(s string) string {
	if s.ends_with(')') {
		return s[..s.len - 1]
	}
	return s
}

fn parse_procedure_signature(rest string, method HttpMethod, path string) ?Procedure {
	paren := rest.index('(') or { return none }
	bang := rest.index('!') or { return none }
	name := rest[..paren].trim_space()
	sig := trim_trailing_paren(rest[paren + 1..bang].trim_space())
	output := trim_trailing_paren(rest[bang + 1..].trim_space())
	return Procedure{
		name:        name
		method:      method
		path:        path
		input_type:  sig
		output_type: output
	}
}

fn extract_interface_name(line string) ?string {
	idx := line.index('interface ') or { return none }
	rest := line[idx + 'interface '.len..]
	return rest.split(' ')[0]
}

fn extract_attr_value(line string, key string) ?string {
	needle := '${key}:'
	idx := line.index(needle) or { return none }
	rest := line[idx + needle.len..].trim_space()
	if rest.starts_with('"') && rest.len > 1 {
		end := rest.index_after('"', 1) or { return none }
		return rest[1..end]
	}
	if rest.starts_with('\'') && rest.len > 1 {
		end := rest.index_after('\'', 1) or { return none }
		return rest[1..end]
	}
	mut val := rest.split(';')[0].trim_space()
	val = val.replace("'", '').replace('"', '')
	return val.trim_string_right(']')
}

fn parse_struct_block(all_lines []string, start_line string) ?TypeDef {
	name := start_line.replace('pub struct ', '').trim_space().split(' ')[0]
	mut fields := []Field{}
	mut idx := -1
	for i, l in all_lines {
		if l == start_line {
			idx = i
			break
		}
	}
	if idx < 0 {
		return none
	}
	for i := idx + 1; i < all_lines.len; i++ {
		line := all_lines[i].trim_space()
		if line == '}' {
			break
		}
		if line.starts_with('pub:') || line == '' {
			continue
		}
		if f := parse_field_line(line) {
			fields << f
		}
	}
	return TypeDef{
		name:   name
		fields: fields
	}
}

fn parse_field_line(line string) ?Field {
	parts := line.split('//')[0].trim_space().split('@')
	if parts.len == 0 {
		return none
	}
	left := parts[0].trim_space()
	mut tokens := []string{}
	for t in left.split(' ') {
		if t != '' {
			tokens << t
		}
	}
	if tokens.len < 2 {
		return none
	}
	name := tokens[0]
	typ := tokens[1]
	mut attrs := ''
	if parts.len > 1 {
		attrs = parts[1].trim_space()
		if attrs.starts_with('[') && attrs.len > 1 {
			attrs = attrs[1..]
		}
		if attrs.ends_with(']') {
			attrs = attrs[..attrs.len - 1]
		}
	}
	return Field{
		name:       name
		kind:       type_kind_from_v(typ)
		array_elem: array_element_type(typ)
		source:     field_source_from_str(field_source_from_attrs(attrs))
		required:   attrs.contains('required')
		header_key: extract_header_key(attrs)
		validators: validators_from_attrs(attrs)
	}
}

fn field_source_from_attrs(attrs string) string {
	if attrs.contains('path') {
		return 'path'
	}
	if attrs.contains('query') {
		return 'query'
	}
	if attrs.contains('header') {
		return 'header'
	}
	if attrs.contains('body') {
		return 'body'
	}
	return 'body'
}

fn extract_header_key(attrs string) string {
	if !attrs.contains('header:') {
		return ''
	}
	return extract_attr_value('@[${attrs}]', 'header') or { '' }
}

fn validators_from_attrs(attrs string) []Validator {
	mut v := []Validator{}
	for rule in ['required', 'email', 'uuid'] {
		if attrs.contains(rule) {
			v << Validator{ rule: rule, value: '' }
		}
	}
	for rule in ['min', 'max', 'min_len', 'max_len'] {
		val := extract_attr_value('@[${attrs}]', rule) or { '' }
		if val != '' {
			v << Validator{ rule: rule, value: val }
		}
	}
	return v
}
