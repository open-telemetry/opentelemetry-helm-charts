// Trimmed-down copy of the operator's pkg/featuregate/featuregate.go, used to
// exercise the parser in check-operator-feature-gates.sh without hitting the
// network. Only the registration shape matters here, not the surrounding code.
package featuregate

var (
	DemoAlphaOne = featuregate.GlobalRegistry().MustRegister(
		"demo.alpha.one",
		featuregate.StageAlpha,
		featuregate.WithRegisterDescription("an alpha gate users can toggle"),
	)

	DemoBetaOne = featuregate.GlobalRegistry().MustRegister(
		"demo.beta.one",
		featuregate.StageBeta,
		featuregate.WithRegisterDescription("a beta gate users can toggle"),
	)

	DemoStableOne = featuregate.GlobalRegistry().MustRegister(
		"demo.stable.one",
		featuregate.StageStable,
		featuregate.WithRegisterDescription("a stable gate that is locked on and must not appear in the chart"),
	)
)
