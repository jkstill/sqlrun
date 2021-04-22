


create or replace package sqlrun_context
is
   procedure set_context_tag (v_tag_in varchar2 );
end;
/

show error package sqlrun_context


create or replace package body sqlrun_context
is
   procedure set_context_tag (v_tag_in varchar2 )
   is
   begin
      dbms_session.set_context(namespace => 'SQLRUN', attribute => 'TAG', value => v_tag_in );
   end;
end;
/

show error package body sqlrun_context


create or replace context sqlrun using sqlrun_context;


