---
name: Bug report
about: Report a bug in a recent version of Freifunk-Berlin Firmware
label: bug
---

<!--

Please carefully fill out the questionaire below to help improve the
timely triaging of issues. Walk through the questions below and use
them as an inspiration for what information you can provide.

Make use of codeblocks (three backticks before and after) where
appropriate (configuration excerpts, log output, etc.). Example:

```
your code goes here
```

You can use the "Preview" tab to check how your issue is going to look
before you actually send it in.

Thank you for taking the time to report a bug with the Gluon project.

-->

### Bug report

**What is the problem?**
<!-- 
- What is not working as expected?
- How is it misbehaving?
- When did the problem first start showing up?
- What were you doing when you first noticed the problem?
- On which devices (vendor, model and revision) is it misbehaving?
- Does the issue appear on multiple devices or targets?
-->

**What is the expected behaviour?**
<!--
- How do you think it should work instead?
- Did it work like that before?
-->

**Firmware Version:**
<!-- 
Please provide a usable Git reference before applying custom patches:

By using a Git reference:
    $ git describe --always
    v2018.2-17-g3abadc28

Or the URL to the relevant commit
    https://github.com/freifunk-berlin/firmware/commit/<commit hash here>

Or look it up from the bottom of the routers Webpage 
    e.g. Powered by LuCI branch (git-19.249.30590-0b5e6d7) / Freifunk Berlin Dev-daily-1907 009f2ea
    the info after the "/" char

Or on the routers console
    - in the login-banner (1st line after the Freifunk-banner)
    - from the file /etc/openwrt-version; line "DISTRIB_REVISION="
-->

**Site Configuration:**
<!--
- What image-type did you use?
- Are you installing from a fresh node or did you do an upgrade?
- Did you just ran the firmware-wizard?
- Did you do manual modifications of the configuration?
- When upgrading, what was the previous version installed?

If you think it might be helpful, upload or provide an URL to your configuration.
But have in mind that the regular backup file, as created by the node, will 
contain sensitive data (encrypted root-password, VPN-certificates, ...)
-->

**Custom patches:**
<!--
Be upfront about any custom patches you have applied to your firmware build, as they might
be part of your problem.
-->

