# What is pipe_logger?
Pipe_logger is a small Oracle package that implement logger functionality. It based on Oracle DBMS_PIPE package.

## Feedback/Issues
Please submit any feedback, suggestions, or issues on the project's [issue page](https://github.com/maxik001/pipe_logger/issues).

# Demo
Any log message consist of timestamp, log message type and log message text.
For example:
```
2018.05.11 12.14.56:254321 [U] Some text
```
where is:
- 2018.05.11 12.14.56:254321 - timestamp
- [W] - log message type
- Some text - log message text


Let's try to generate different log messages:
```sql
declare   
  i PLS_INTEGER;  
  msg_type VARCHAR2(256);
begin  
  for i in 1 .. 10 loop    
    msg_type := case round(dbms_random.value() * 4)      
      when 1 then 'info'      
      when 2 then 'warning'      
      when 3 then 'error'      
      else 'others'    
    end;
    
    pipe_logger.msg_send('Log message ' || i, msg_type);   
  end loop;
end;
```

And then read them:
```sql
begin  
  pipe_logger.msg_receive(7);
end;
```

# Documentation
...

# License
This project is uses the [MIT license](LICENSE).
