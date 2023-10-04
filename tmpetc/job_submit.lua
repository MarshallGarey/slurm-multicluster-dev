-- job_submit.lua
--

prefix=""
inspect = require("inspect")

--This requires lua-posix to be installed
function posix_sleep(n)
	local Munistd = require("posix.unistd")
	local rc
	slurm.log_info("sleep for %u seconds", n)
	rc = Munistd.sleep(n)
	--rc will be 0 if successful or non-zero for amount of time left
	--to sleep
	return rc
end

--This commented out function is a wrapper for the posix "sleep"
--function in the lua-posix posix.unistd module.
function sleep_wrapper(n)
	--return slurm.SUCCESS, ""
	local rc, ret_str
	rc = posix_sleep(n)
	if (rc ~= 0) then
		ret_str = "Sleep interrupted, " .. tostring(rc) .. " seconds left"
		rc = slurm.ERROR
	else
		ret_str = "Success"
		rc = slurm.SUCCESS
	end
	return rc, ret_str
end

-- Do not allow interactive jobs longer than 4 hours except for certain users
function validate_interactive_job(job_desc, uid)
	if job_desc['script'] ~= nil then
		return slurm.SUCCESS -- no limit for batch jobs
	end
	local privileged = false
	local privileged_users = { 0, --[[SlurmUser, SpecialUser--]] 1017 }
	for i,v in ipairs(privileged_users) do
		if uid == v then
			privileged = true
			break
		end
	end
	--if uid == 0 or uid == 1017 --[[ or uid == SpecialUser --]] then
	if (privileged) then
		slurm.log_info("Interactive job allowed for uid: %u", uid)
	else
		local time_limit = job_desc['time_limit']
		if (time_limit == slurm.NO_VAL) then
			slurm.log_user("You must request a time limit within 4 hours for interactive jobs")
			return slurm.ESLURM_INVALID_TIME_LIMIT
		elseif (time_limit > (4 * 60)) then
			slurm.log_user("Interactive jobs for time longer than 4h forbidden")
			return slurm.ESLURM_INVALID_TIME_LIMIT
		end
	end
	return slurm.SUCCESS
end

function log_numtasks(job_desc)
	local nt = job_desc["num_tasks"]
	if (nt ~= nil) then
		slurm.log_info("requested num_tasks = %d", nt)
	else
		slurm.log_info("requested num_tasks = nil")
	end
end

function log_argv(job_desc)
	local prefix = "slurm_job_submit"
	local argv = job_desc['argv']
	if (argv ~= nil) then
		-- Lua ipairs starts looking for key==1, then continues looking
		-- for key==2,3,4,... until there are no more keys in that
		-- sequential order.
		-- We made argv start at index 0; because all datastructures in
		-- lua are tables, the index is the key. That means that the
		-- ipairs won't work.
		--for i,v in ipairs(argv) do
		--	slurm.log_user("%s: argv[%d]=%s", prefix, i, v)
		--end
		-- Using "pairs" rather than "ipairs" will iterate over
		-- all key-value pairs in the table, but does not guarantee any
		-- particular order.
		--for k,v in pairs(argv) do
		--	slurm.log_user("%s: key=%s val==%s", prefix, k, v)
		--end
		-- We can also choose to iterate using a while loop from 0
		local i = 0
		while (i < job_desc['argc']) do
			slurm.log_user("%s: argv[%d]=%s", prefix, i, argv[i])
			i = i + 1
		end
	end
end

function log_parts(part_list)
	slurm.log_info("%s: partitions:\n%s",
		prefix, inspect(part_list))
	for pname,t in pairs(part_list) do
		slurm.log_info("%s: Part %s: nodes=%s",
			prefix, pname, t['nodes'])
	end
end

function log_resvs()
	slurm.log_info("%s: reservations:\n%s",
		prefix, inspect(slurm.reservations))
	for rname,t in pairs(slurm.reservations) do
		slurm.log_info("Resv %s: duration=%u", rname, t['duration'])
	end
end

function slurm_job_submit(job_desc, part_list, submit_uid)
	prefix = "slurm_job_submit"
	--local rc = validate_interactive_job(job_desc, submit_uid)
	--if rc ~= slurm.SUCCESS then
	--	return rc
	--end
	--return slurm.SUCCESS

	--slurm.log_info("%s: %s", prefix,
	--	inspect(job_desc['argv']))
	--log_argv(job_desc)
	log_resvs()
	log_parts(part_list)
	log_numtasks(job_desc)

	--Show that multiple threads cannot run this job submit script
	--concurrently by sleeping.
	--sleep_wrapper(10)
	--slurm.log_info("XXX Job submit")
	--os.execute("sleep 10")

	if (job_desc["tres_per_job"] ~= nil) then
		slurm.log_info("Job requested tres_per_job=%s", job_desc["tres_per_job"])
	end

	return slurm.SUCCESS
end


function  slurm_job_modify(job_desc, job_ptr, part_list, modify_uid)
	prefix = "slurm_job_modify"
	--local rc = validate_interactive_job(job_desc, modify_uid)
	--if rc ~= slurm.SUCCESS then
	--	return rc
	--end
	return slurm.SUCCESS
end
