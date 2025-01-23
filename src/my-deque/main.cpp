#include <cstddef>
#include <memory>
#include <print>
#include <stdexcept>

constexpr auto MEM_ALC_ERR = "Memory allocation error";
constexpr auto INV_ACS_ERR = "Invalid memory access";
constexpr auto DEQ_EMT_ERR = "Deque is empty";

template <typename T>
struct Node {
    T                        data;
    std::shared_ptr<Node<T>> next = nullptr;
    std::shared_ptr<Node<T>> prev = nullptr;

    Node() :
        data(0) {}
    Node(T data) :
        data(data) {}
};

template <typename T>
class Deque
{
private:
    std::shared_ptr<Node<T>> front = nullptr;
    std::shared_ptr<Node<T>> rear  = nullptr;
    std::size_t              size  = 0;

    [[nodiscard]] auto isEmpty() const -> bool
    {
        return size == 0;
    }

    auto makeNode(const T &val) -> std::shared_ptr<Node<T>>
    {
        auto newNode = std::make_shared<Node<T>>(val);
        if (!newNode) {
            throw std::runtime_error(MEM_ALC_ERR);
        }

        return newNode;
    }

public:
    void pushFront(const T &val)
    {
        auto newNode = makeNode(val);

        if (isEmpty()) {
            front = rear = newNode;
        } else {
            newNode->next = front;
            front->prev   = newNode;
            front         = newNode;
        }

        size++;
    }

    void pushBack(const T &val)
    {
        auto newNode = makeNode(val);

        if (isEmpty()) {
            front = rear = newNode;
        } else {
            newNode->prev = rear;
            rear->next    = newNode;
            rear          = newNode;
        }

        size++;
    }

    void insert(const std::size_t idx, const T &val)
    {
        if (idx > size - 1)
            throw std::runtime_error(INV_ACS_ERR);

        if (idx == 0) {
            pushFront(val);
            return;
        }

        auto tempNode = front;
        for (int i = 0; i < idx; i++) {
            if (i == idx)
                break;
            tempNode = tempNode->next;
        }

        auto newNode = makeNode(val);

        newNode->next        = tempNode;
        newNode->prev        = tempNode->prev;
        tempNode->prev->next = newNode;
        tempNode->prev       = newNode;

        size++;
    }

    auto popFront() -> T
    {
        if (isEmpty())
            throw std::runtime_error(DEQ_EMT_ERR);

        const T popedVal = front->data;

        if (size == 1) {
            front.reset();
            rear.reset();
        } else {
            front = front->next;
            front->prev.reset();
        }

        return popedVal;
    }

    auto popBack() -> T
    {
        if (isEmpty())
            throw std::runtime_error(DEQ_EMT_ERR);

        const T popedVal = rear->data;

        if (size == 1) {
            front.reset();
            rear.reset();
        } else {
            rear = rear->prev;
            rear->next.reset();
        }

        size--;

        return popedVal;
    }

    auto operator[](const std::size_t &idx) -> T &
    {
        if (idx > size - 1) {
            throw std::runtime_error(INV_ACS_ERR);
        }

        auto tempNode = front;
        for (std::size_t i = 0; i < idx; i++) {
            if (i == idx)
                break;
            tempNode = tempNode->next;
        }

        return tempNode->data;
    }

    auto operator[](const std::size_t &idx) const -> T
    {
        if (idx > size - 1) {
            throw std::runtime_error(INV_ACS_ERR);
        }

        auto tempNode = front;
        for (std::size_t i = 0; i < idx; i++) {
            if (i == idx)
                break;
            tempNode = tempNode->next;
        }

        return tempNode->data;
    }

    void clear()
    {
        while (!isEmpty()) {
            popBack();
        }
    }

    [[nodiscard]] auto getSize() const -> std::size_t
    {
        return size;
    }

    void print() const
    {
        for (std::size_t i = 0; i < size; i++) {
            std::print("{} ", (*this)[i]);
        }
        std::println();
    }
};

auto main() -> int
{
    Deque<std::string> d;

    while (true) {
        for (int i = 0; i < 10; i++) {
            d.pushBack("hello");
        }

        d.print();

        d.clear();
    }
}
