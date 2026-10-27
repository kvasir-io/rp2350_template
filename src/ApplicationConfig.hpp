#pragma once
#include "HWConfig.hpp"
///

#include <kvasir/Runtime/Standard.hpp>
#include <kvasir/StartUp/StartUp.hpp>

using Clock = HW::SystickClock;

// Runtime::Standard: the fault handler, the stack protector, a boot-loop guard and the boot report (the version, the
// reset cause and what the run before this one ended in, before main) - one entry that stands for the four
using Startup = Kvasir::Startup::Startup<HW::ClockSettings,
                                         Clock,
                                         HW::ComBackend,
                                         Kvasir::Runtime::Standard<Clock>,
                                         HW::PinConfig>;

// The whole-image choices (hooks), each a class template specialised for Kvasir::Tag::User that names its choice as
// `type`; the table with every hook, its default and its legal values is kvasir/Port/Hooks.hpp. Uncomment to change
// one (after `using Startup` where it names the Startup):
//
//   template<> struct Kvasir::Panic::PanicReaction<Kvasir::Tag::User> { using type = Kvasir::Panic::OnPanic::Halt; };
//       // default OnPanic::Default: record the panic, reboot the chip
//   template<> struct Kvasir::Panic::FatalStartReaction<Kvasir::Tag::User> {
//       using type = Kvasir::Startup::SafeStateOf<::Startup>;   // default NoFatalStart; needed with Hook::SafeState
//   };
//   template<> struct Kvasir::Fault::FaultReaction<Kvasir::Tag::User> { using type = Kvasir::Fault::OnFault::Halt; };
//       // default OnFault::Panic: a fault ends as a panic
//   template<> struct Kvasir::Register::WaitPolicy<Kvasir::Tag::User> {
//       using type = Kvasir::Register::OnTimeout::Panic;
//   };
//       // default OnTimeout::Unbounded: the chip's register waits are plain loops (specialise before HWConfig.hpp)
//   template<> struct Kvasir::CrashRecord::RecordFormat<Kvasir::Tag::User> {
//       using type = Kvasir::CrashRecord::Full<>;
//   };
//       // default Full<>: every record with its options
//   Kvasir::Health::StarvationReaction (OnStarvation::StopFeeding), Kvasir::BootGuard::LimitReaction (OnLimit::Log),
//   Kvasir::ImageCheck::MismatchReaction (OnMismatch::Log), Kvasir::Check::SoftFailureReaction (OnSoftFailure::Panic
//   in sanitize, Log elsewhere), Kvasir::Atomic::CriticalSectionPolicy, Kvasir::Startup::HookProfiler: the same way.
