import Config

config :logger, level: :error

config :mix_test_watch,
  tasks: [
    "test --stale --max-failures 1 --seed 0 --trace --exclude pending",
    "test --max-failures 1 --exclude pending"
  ]
