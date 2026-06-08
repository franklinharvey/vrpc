# hello

Smallest possible vrpc server: one manually registered GET route returning JSON.

## Run

```bash
v run .
```

Server listens on **http://127.0.0.1:3001**.

## Try it

```bash
curl http://127.0.0.1:3001/hello
# {"message":"hello from vrpc"}
```

For contract-first services, OpenAPI, and codegen, see [../users/README.md](../users/README.md).
