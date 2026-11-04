# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Shipped in report-only mode (config.content_security_policy_report_only is
# true below): browsers log violations but the policy is NOT enforced, so it
# cannot break the app. The app loads Bootstrap, Plotly.js and Google
# Analytics and uses GitHub/Google OAuth, so the directives below are kept
# deliberately permissive. Tighten them once report-only data confirms what
# the app actually needs, then flip report_only off.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    # :unsafe_inline / :unsafe_eval cover the inline Google Analytics snippet
    # and Plotly.js; drop them once scripts are nonce-tagged.
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval
    # Bootstrap and other inline styles need :unsafe_inline.
    policy.style_src   :self, :https, :unsafe_inline
    # Google Analytics beacons and OAuth redirects use outbound connections.
    policy.connect_src :self, :https
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Report violations without enforcing the policy. Keep this true until the
  # directives above are tightened and verified.
  config.content_security_policy_report_only = true
end
