# intermediate Makefile to decide if doing a local build or a build on the buildbot
# this is decided basis of the IS_BUILDBOT environment

buildtype:
ifeq ($(IS_BUILDBOT),yes)
	$(info running in BUILDBOT, using Makefile.buildbot)
	$(MAKE) -f Makefile.buildbot
else
	$(info local build, using Makefile.buildlocal)
	$(MAKE) -f Makefile.buildlocal
endif
