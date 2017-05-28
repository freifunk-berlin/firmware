.PHONY: $(IB_JOB_TARGETS)
$(IB_JOB_TARGETS):
	./ib-generate-firmware.sh -i $(IB_FILE) -j $(@:ib-job/%=%) -d $(DEST_DIR)
