#include "ApplicationConfig.hpp"
//

#include <kvasir/StartUp/StartUp.hpp>
#include <kvasir/Util/Periodic.hpp>

int main() {
    // the boot line (version, reset cause, what the run before this one ended in) came from Boot::Report before main

    // every 500 ms from now (not from the clock's epoch: that would burst uptime / 500 ms toggles
    // at boot on a clock that does not start at 0)
    Kvasir::Every<Clock> blink{std::chrono::milliseconds{500}};
    bool                 ledState = false;

    while(true) {
        if(blink.due()) {
            if(ledState) {
                apply(clear(HW::Pin::led{}));
            } else {
                apply(set(HW::Pin::led{}));
            }
            ledState = !ledState;
            UC_LOG_D("Led: {}", ledState);
        }
        Startup::run<
          Kvasir::Hook::MainLoop>();   // StackProtector, the boot guard and whoever else extends it
    }
}

template struct Kvasir::Startup::Start<Startup>;
