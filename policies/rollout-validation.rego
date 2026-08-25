package argoproj.rollouts

deny[msg] {
    input.kind == "Rollout"
    not input.spec.strategy.canary
    not input.spec.strategy.blueGreen
    msg := "Rollout must specify either a canary or blueGreen strategy"
}

deny[msg] {
    input.kind == "Rollout"
    input.spec.strategy.canary
    not input.spec.strategy.canary.analysis
    msg := "Canary rollout must define an analysis block for automated rollback"
}
