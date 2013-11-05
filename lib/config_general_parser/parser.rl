%%{

  machine config_general;
  
  attribute = ^(space | '=')+ %attributeName space* '=' space* ('"' ^'"'* %attribute '"');
  
  main := space* element space*;
}%%

%% write data;
