# Swift-scripts


## closure_leak_check.sh
Checks files for possible strong retain cycles. Looks for closures that uses self and does not declare it weak in capture list. Though this does't necessarily mean that it is strong retain cycle, so there will be also false positives, it proves usefull for a quick check. 

Usage:

```
./closure_leak_check.sh LeakyViewController.swift
```

Or on directory:
```
./closure_leak_check.sh Source/
```

Output:
![Console closure leak check](http://tomaskohout.cz/public-images/leak_check.png)
