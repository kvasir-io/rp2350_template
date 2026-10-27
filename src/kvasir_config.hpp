#pragma once
// The image's config header: what the libraries look up by uc_log::Tag::User - the log sink and the log clock, both
// complete - and the chip variant. uc_log/uc_log.hpp includes it first (UC_LOG_CONFIG_HEADER, set by
// target_configure_kvasir for src/kvasir_config.hpp), so every TU that logs sees the same specialisations before any
// log line. Never include uc_log/uc_log.hpp here, directly or through another header (that is a named #error).

#include "chip/rp_common/DebuggerPresent.hpp"

#include <chip/rp_common/WaitBounds.hpp>   // Register::CpuHzCeiling<Tag::User>: the loss policy's CPU ceiling
// the chip variant: the chip headers (core/Systick.hpp, through SystickLogClock.hpp) read it
#include <chip/rp_common/PinConfig.hpp>

// Kvasir::Chip::part: from the chip package (chip_rp2350, KVASIR_RP2350_MPU=RP2350A, the default)

#include <kvasir/Log/RttSink.hpp>
#include <kvasir/Log/SystickLogClock.hpp>
#include <uc_log/LogClock.hpp>

namespace uc_log {
// one 16 KB RTT ring; a dropped log line says so in the next one ("⚠ N log records lost")
template<>
struct ComBackend<uc_log::Tag::User> : public Kvasir::Log::RttSink<> {};
}   // namespace uc_log

namespace HW {
static constexpr auto clockSpeedValue = 150'000'000;

// the core's SysTick at the processor clock, its overrun counter good for 15 years
using SystickClock = Kvasir::Log::SystickLogClock<clockSpeedValue>;
}   // namespace HW

namespace uc_log {
template<>
struct LogClock<uc_log::Tag::User> : public HW::SystickClock {};
}   // namespace uc_log
