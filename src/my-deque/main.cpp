#include "my-deque.h"

auto main() -> int
{
    Deque<int> d;

    for (int i = 0; i < 10; i++) {
        d.pushBack(i * 10);
    }
    d.print();

    std::println("poped: {}", d.popFrom(0));
    d.print();

    d.clear();
    d.print();

    return EXIT_SUCCESS;
}
