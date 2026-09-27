#include <etesca/core.hpp>

#include <cstdio>

int main() {
    const char* const version = etesca::version();
    if (version == nullptr) {
        return 1;
    }
    std::puts(version);
    return 0;
}
