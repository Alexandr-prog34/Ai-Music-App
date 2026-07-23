# Unrolled Linked List

![C++](https://img.shields.io/badge/C%2B%2B-23-blue.svg)
![CMake](https://img.shields.io/badge/build-CMake-informational.svg)
![Tests](https://img.shields.io/badge/tests-GoogleTest-success.svg)

An allocator-aware, STL-style implementation of an **Unrolled Linked List** in modern C++.

Unlike a classic linked list, where every node stores one element, an unrolled linked list stores several elements inside each node. This reduces per-element allocation overhead and improves data locality while preserving bidirectional traversal and efficient modifications.

## Features

- Generic container: `unrolled_list<T, NodeMaxSize, Allocator>`
- Configurable node capacity through the `NodeMaxSize` template parameter
- Custom allocator support through `std::allocator_traits`
- Allocator rebinding for node allocation and element lifetime management
- Bidirectional mutable and const iterators
- Reverse iterator types and accessors
- Copy and move construction
- Copy and move assignment
- Range, fill, allocator and initializer-list constructors
- `push_front`, `push_back`, `pop_front` and `pop_back`
- Single-element and count-based `insert`
- Single-element and range `erase`
- `front`, `back`, `size`, `empty`, `clear`, `swap` and `get_allocator`
- Automatic node splitting when inserting into a full node
- Support for non-default-constructible element types
- Google Test test suite

## Container Design

The container is declared as:

```cpp
template<
    typename T,
    std::size_t NodeMaxSize = 10,
    typename Allocator = std::allocator<T>
>
class unrolled_list;
```

Each node contains:

- links to the previous and next nodes;
- the number of constructed elements;
- aligned raw storage for up to `NodeMaxSize` objects.

Elements are constructed directly inside node storage through allocator traits. When an insertion targets a full node, the node is split and part of its elements is moved into a newly allocated node.

```text
head                                                   tail
 ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
 │ 1 │ 2 │ 3 │ 4 │ <-> │ 5 │ 6 │ 7     │ <-> │ 8 │ 9         │
 └───────────────┘     └───────────────┘     └───────────────┘
       node                  node                  node
```

## Requirements

- C++23-compatible compiler
- CMake 3.12 or newer
- Internet access during the first CMake configuration so GoogleTest can be fetched

## Build

Clone the repository:

```bash
git clone https://github.com/Alexandr-prog34/UnrolledLinkedList-STL.git
cd UnrolledLinkedList-STL
```

Configure and build the project:

```bash
cmake -S . -B build
cmake --build build
```

## Run Tests

The test suite is registered with CTest:

```bash
ctest --test-dir build --output-on-failure
```

Alternatively, run the test executable directly:

```bash
./build/tests/unrolled-list-lib-tests
```

On multi-configuration generators such as Visual Studio, the executable may be located inside a configuration directory:

```bash
./build/tests/Debug/unrolled-list-lib-tests
```

## Usage

Add the `lib` directory to your include path and include the container header:

```cpp
#include <unrolled_list.h>

#include <iostream>
#include <iterator>

int main() {
    unrolled_list<int, 4> values{1, 2, 3};

    values.push_front(0);
    values.push_back(4);

    auto position = values.begin();
    std::advance(position, 2);
    values.insert(position, 42);

    for (const int value : values) {
        std::cout << value << ' ';
    }
}
```

Output:

```text
0 1 42 2 3 4
```

The second template argument controls the maximum number of elements stored in one node:

```cpp
unrolled_list<int> default_capacity;      // 10 elements per node
unrolled_list<int, 32> larger_nodes;      // 32 elements per node
```

A custom allocator can be supplied as the third template argument:

```cpp
using list_type = unrolled_list<int, 16, CustomAllocator<int>>;

CustomAllocator<int> allocator;
list_type values(allocator);
```

## Public API

### Construction and assignment

```cpp
unrolled_list();
explicit unrolled_list(const allocator_type& allocator);

unrolled_list(
    size_type count,
    const value_type& value,
    const allocator_type& allocator = allocator_type()
);

template<typename InputIt>
unrolled_list(
    InputIt first,
    InputIt last,
    const allocator_type& allocator = allocator_type()
);

unrolled_list(
    std::initializer_list<value_type> values,
    const allocator_type& allocator = allocator_type()
);

unrolled_list(const unrolled_list& other);
unrolled_list(unrolled_list&& other) noexcept;
unrolled_list(unrolled_list&& other, const allocator_type& allocator);

unrolled_list& operator=(const unrolled_list& other);
unrolled_list& operator=(unrolled_list&& other) noexcept;
```

### Iterators

```cpp
iterator begin();
iterator end();

const_iterator begin() const;
const_iterator end() const;

const_iterator cbegin() const;
const_iterator cend() const;

reverse_iterator rbegin();
reverse_iterator rend();

const_reverse_iterator rbegin() const;
const_reverse_iterator rend() const;

const_reverse_iterator crbegin() const;
const_reverse_iterator crend() const;
```

### Element access

```cpp
reference front();
const_reference front() const;

reference back();
const_reference back() const;
```

Calling `front()` or `back()` on an empty container is undefined, matching the convention used by standard sequence containers.

### Capacity

```cpp
bool empty() const;
size_type size() const;
size_type max_size() const;
```

### Modifiers

```cpp
void clear() noexcept;

void push_back(const value_type& value);
void push_front(const value_type& value);

void pop_back() noexcept;
void pop_front() noexcept;

iterator insert(const_iterator position, const value_type& value);
iterator insert(
    const_iterator position,
    size_type count,
    const value_type& value
);

iterator erase(const_iterator position) noexcept;
iterator erase(
    const_iterator first,
    const_iterator last
) noexcept;

void swap(unrolled_list& other) noexcept(
    std::is_nothrow_swappable_v<value_type>
);
```

### Allocator access

```cpp
allocator_type get_allocator() const;
```

## Complexity

Let:

- `N` be the total number of elements;
- `B` be `NodeMaxSize`;
- `M` be the number of inserted or erased elements.

Because `B` is a compile-time fixed node capacity, operations bounded by `B` are constant with respect to the total container size `N`.

| Operation | Complexity |
|---|---:|
| `empty`, `size` | `O(1)` |
| `front`, `back` | `O(1)` |
| `begin`, `end` | `O(1)` |
| Iterator increment/decrement | `O(1)` |
| `push_back` | `O(1)` |
| `push_front` | `O(B)`, effectively `O(1)` for fixed `B` |
| `pop_back` | `O(1)` |
| `pop_front` | `O(B)`, effectively `O(1)` for fixed `B` |
| Single-element `insert` | `O(B)`, effectively `O(1)` for fixed `B` |
| Count-based `insert` | `O(M × B)` |
| Single-element `erase` | `O(B)`, effectively `O(1)` for fixed `B` |
| Range `erase` | `O(M × B)` |
| `clear` | `O(N)` |
| Equality comparison | `O(N)` |

Finding an arbitrary position is linear because the container provides bidirectional rather than random-access iterators.

## Exception Safety

The project includes dedicated tests with throwing element types and custom allocators.

The tested scenarios include:

- cleanup after an exception during range construction;
- preserving container invariants when `push_front` fails;
- preserving container invariants when `push_back` fails;
- matching node allocation and deallocation counts.

The current API declares `clear`, `pop_front`, `pop_back` and both `erase` overloads as `noexcept`.

## Testing

The Google Test suite covers:

- comparison with `std::list` for mixed push, pop and insert operations;
- single-element modification and container lifecycle behavior;
- clearing and reusing a container;
- custom allocator allocation and deallocation;
- exception-safety scenarios;
- support for non-default-constructible types;
- API checks inspired by the standard named requirements for:
  - `Container`;
  - `AllocatorAwareContainer`;
  - `SequenceContainer`;
  - `ReversibleContainer`.

GoogleTest and GoogleMock are downloaded automatically through CMake `FetchContent`.

## Project Structure

```text
.
├── bin
│   ├── CMakeLists.txt
│   └── main.cpp
├── lib
│   └── unrolled_list.h
├── tests
│   ├── CMakeLists.txt
│   ├── allocator_ut.cpp
│   ├── exception_safety_ut.cpp
│   ├── named_requirements_ut.cpp
│   ├── no_default_constructible_ut.cpp
│   └── simple_ut.cpp
├── CMakeLists.txt
└── README.md
```

## Motivation

This project explores lower-level C++ container implementation techniques:

- manual object lifetime management;
- aligned raw storage;
- allocator-aware design;
- iterator implementation;
- copy and move semantics;
- exception safety;
- node-based data structures;
- compile-time interface validation with concepts.

It is intended as an educational implementation of an STL-style sequence container and as a practical study of modern C++ memory-management mechanisms.
