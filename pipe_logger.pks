CREATE OR REPLACE PACKAGE PIPE_LOGGER AS

  -- Author: Maksim O. Gusev
  -- Contact: maxgusev@gmail.com
  
  procedure pipe_create;
  procedure pipe_remove;

  procedure msg_send(msg_text VARCHAR2, msg_type VARCHAR2 default NULL);
  procedure msg_receive(msg_count PLS_INTEGER default NULL);

END PIPE_LOGGER;
