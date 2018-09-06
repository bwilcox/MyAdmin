# These are some useful queries.  
These are queries which were sometimes not trivial to come up with.  I can't take credit for them, I'm just posting them so I know where to find them again if I ever need them.

## Find servers which do not have a role assigned
```
puppet query 'nodes['certname']{! certname in resources['certname']{type="Class" and title~"[Rr]ole"}}'
```

## Find servers which don't have a package
This one requires that you have the package inventory service turned on.

```
puppet query "nodes[certname]{! certname in package_inventory[certname]{ package_name ~ 'audit' }}"
```
