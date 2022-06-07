# Rules for manageable GDScript

## 1. Code Organization
### 1.1 Signal connection
User-defined signals should be connected through code. Built-in signals - through the editor UI with the default function names. Reason: when you look where the function is called through Ctrl-Shift-V, you wil never used events connected from the UI.
### 1.2 Signal pass through
When you need to pass the signal to the upper level in the tree, use global class State instead. Reason - boilerplate excessive code in the middle node.


## 2. Code Style
- Always use type hints, when possible.
- Functions have 2 line breaks before them.
- Consult general GDScript style suggested by the editor otherwise.


## 3. Godot quirks (as of 3.4.4)