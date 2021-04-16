

exec sqlrun_context.set_context_tag('SQLRELAY');


select sys_context('SQLRUN','TAG') from dual;

