
-- test the use of bind variables with plsql
begin
	insert into plsql_test
	values(?,?);
	commit;
end;

