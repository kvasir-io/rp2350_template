#include "ApplicationConfig.hpp"
//

#include <cmake_git_version/version.hpp>

int main() {
    UC_LOG_D("{}", CMakeGitVersion::FullVersion);
    UC_LOG_D("Reset cause: {}", Kvasir::PM::reset_cause());

    auto next     = Clock::time_point{};
    bool ledState = false;

    while(true) {
        auto const now = Clock::now();
        if(now > next) {
            next += std::chrono::milliseconds{500};
            if(ledState) {
                apply(clear(HW::Pin::led{}));
            } else {
                apply(set(HW::Pin::led{}));
            }
            ledState = !ledState;
            UC_LOG_D("Led: {}", ledState);
        }
        StackProtector::handler();
    }
}

KVASIR_START(Startup)
