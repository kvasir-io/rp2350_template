#pragma once

// uc_log.hpp reads kvasir_config.hpp (log sink, log clock, chip variant) before anything else. It comes first because
// the RP chip headers read the chip variant (Chip::part) that the config header states; every other header in any
// order.
#include <uc_log/uc_log.hpp>
// then the chip and its drivers
#include <chip/chip.hpp>

namespace HW {
static constexpr auto crystalSpeed = 12'000'000;

using ComBackend = uc_log::ComBackend<uc_log::Tag::User>;

// The clock tree (chip/rp_common/clock_config.hpp): Provides (every driver's clock checked against it), the clock
// init, and what the chip's Clocks::DegradedBoot and a Clocks::Resus need of it - with the two numbers spelled once.
using ClockSettings = Kvasir::DefaultClockSettings::Settings<clockSpeedValue, crystalSpeed>;
}   // namespace HW
