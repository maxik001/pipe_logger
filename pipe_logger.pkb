CREATE OR REPLACE PACKAGE BODY PIPE_LOGGER AS
  
  -- Author: Maksim O. Gusev
  -- Contact: maxgusev@gmail.com

  -- Global config
  pipe_name VARCHAR2(30) := 'pipe_logger';    -- Default pipe name
  msg_timestamp_format VARCHAR2(256) := 'YYYY.MM.DD HH24.MI.SS:FF6';  -- Look like '2018.05.10 10.16.51:662511'
  send_timeout PLS_INTEGER := 5;              -- Default send timeout in seconds
  receive_timeout PLS_INTEGER := 1;           -- Default receive timeout in seconds

  -- Tools
  CRLF char(2) := chr(13) || chr(10);       -- Csarriage return, line feed
  
  -- Exceptions
  E_MSG_RECEIVE_TIMEOUT EXCEPTION;
  E_MSG_SEND_TIMEOUT EXCEPTION;

  E_MSG_TOO_LARGE EXCEPTION;

  E_BUFFER_OVERFLOW EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_BUFFER_OVERFLOW, -06558);

  E_INTERRUPT EXCEPTION;
  E_UNKNOWN EXCEPTION;
  
  -- Functions
  function format_msg_type (msg_type VARCHAR2) return VARCHAR2 as
    retval VARCHAR2(3);
  BEGIN
    retval :=
      case msg_type
        when 'info' then  '[I]'
        when 'warning' then'[W]'
        when 'error' then '[E]'
        when null then '[ ]'
        else '[U]'
      end;
    
    return retval;
  END format_msg_type;
  
  -- Procedures
  
  -- pipe_create
  procedure pipe_create AS
    retcode PLS_INTEGER;
  BEGIN
    retcode := SYS.DBMS_PIPE.CREATE_PIPE(pipe_name);
    if retcode = 0 then dbms_output.put_line('Successfully'); else RAISE E_UNKNOWN; end if;
  EXCEPTION
    when E_UNKNOWN then dbms_output.put_line('Error when create pipe. Retcode ' || retcode);
    when OTHERS then dbms_output.put_line('SQLCODE: ' || SQLCODE || CRLF || 'SQLERRM: ' || SQLERRM);
  END pipe_create;

  -- pipe_remove
  procedure pipe_remove AS
    retcode PLS_INTEGER;
  BEGIN
    retcode := SYS.DBMS_PIPE.REMOVE_PIPE(pipe_name);
    if retcode = 0 then dbms_output.put_line('Successfully'); else RAISE E_UNKNOWN; end if;
  EXCEPTION
    when E_UNKNOWN then dbms_output.put_line('Error when remove pipe. Retcode ' || retcode);
    when OTHERS then dbms_output.put_line('SQLCODE: ' || SQLCODE || CRLF || 'SQLERRM: ' || SQLERRM);
  END pipe_remove;
  
  -- msg_send
  procedure msg_send(msg_text VARCHAR2, msg_type VARCHAR2 default NULL) AS
    msg_timestamp VARCHAR2(256);
    retcode PLS_INTEGER;
  BEGIN
    msg_timestamp := to_char(SYSTIMESTAMP, msg_timestamp_format);
  
    dbms_pipe.pack_message(msg_timestamp);
    dbms_pipe.pack_message(format_msg_type(msg_type));
    dbms_pipe.pack_message(msg_text);
    
    retcode := dbms_pipe.send_message(pipe_name, send_timeout);

    if retcode = 1 then raise E_MSG_SEND_TIMEOUT;
    elsif retcode = 3 then raise E_INTERRUPT;
    end if;
  EXCEPTION
    when E_BUFFER_OVERFLOW then dbms_output.put_line('Message too large. Buffer overflow!');
    when E_INTERRUPT then dbms_output.put_line('An interrupt occurred.');
    when OTHERS then dbms_output.put_line('SQLCODE: ' || SQLCODE || CRLF || 'SQLERRM: ' || SQLERRM);
  END msg_send;

  -- msg_receive
  procedure msg_receive(msg_count PLS_INTEGER default NULL) AS
    msg_timestamp VARCHAR2(256);
    msg_type VARCHAR2(3);
    msg_text VARCHAR2(256);
    
    retcode PLS_INTEGER;
    i PLS_INTEGER := 0;
  BEGIN
    loop
      -- Receive next message
      retcode := dbms_pipe.receive_message(pipe_name, receive_timeout);

      if retcode = 0 then
        dbms_pipe.unpack_message(msg_timestamp);
        dbms_pipe.unpack_message(msg_type);
        dbms_pipe.unpack_message(msg_text);
          
        dbms_output.put_line(msg_timestamp || ' ' || msg_type || ' ' || msg_text);
      else 
        if retcode = 1 then raise E_MSG_RECEIVE_TIMEOUT;
        elsif retcode = 2 then raise E_MSG_TOO_LARGE;
        elsif retcode = 3 then raise E_INTERRUPT;
        else raise E_UNKNOWN;
        end if;
      end if;      

      -- Break cycle if exceed messages count limit
      i := i + 1;
      if msg_count is not null and i >= msg_count then return; end if;
      
      exit when retcode != 0;      
    end loop;
  EXCEPTION
    when E_MSG_RECEIVE_TIMEOUT then dbms_output.put_line('Timeout limit exceeded!');
    when E_MSG_TOO_LARGE then dbms_output.put_line('Record in the pipe is too large for the buffer!');
    when E_INTERRUPT then dbms_output.put_line('An interrupt occurred.');
    when E_UNKNOWN then dbms_output.put_line('Unknown exception. Retcode ' || retcode);
    when OTHERS then dbms_output.put_line('SQLCODE: ' || SQLCODE || CRLF || 'SQLERRM: ' || SQLERRM);
  END msg_receive;

END PIPE_LOGGER;
