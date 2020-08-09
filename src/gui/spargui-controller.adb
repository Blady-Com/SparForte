-------------------------------------------------------------------------------
-- NAME (body)                  : spargui-controller.adb
-- AUTHOR                       : Pascal Pignard
-- ROLE                         : User interface control unit.
-- NOTES                        : Ada 2012, GNOGA 1.6 beta
--
-- COPYRIGHT                    : (c) Pascal Pignard 2020
-- LICENCE                      : CeCILL V2 (http://www.cecill.info)
-- CONTACT                      : http://blady.pagesperso-orange.fr
-------------------------------------------------------------------------------

with Gnoga.Gui.Base;
with Gnoga.Gui.View.Grid;
with Gnoga.Gui.Plugin.Pixi;
with Gnoga.Gui.Plugin.Ace_Editor;
with Gnoga.Gui.Navigator;
with Gnoga.Server.Connection;
--  with ZanyBlue.Text.Locales;
with spar;

with SparGUI.View;
--  with SparGUI_messages.SparGUI_Strings;

package body SparGUI.Controller is

   --  Handlers
   procedure On_Exit (Object : in out Gnoga.Gui.Base.Base_Type'Class);
   procedure On_Quit (Object : in out Gnoga.Gui.Base.Base_Type'Class);
   procedure On_Click (Object : in out Gnoga.Gui.Base.Base_Type'Class);

   procedure On_Exit (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : constant SparGUI.View.Default_View_Access := SparGUI.View.Default_View_Access (Object.Parent.Parent);
      Dummy_Last_View : Gnoga.Gui.View.View_Type;
   begin
      View.Remove;
      Dummy_Last_View.Create (View.Main_Window.all);
      Dummy_Last_View.Put_Line ("Disconnected!");
      View.Main_Window.Close;
      View.Main_Window.Close_Connection;
   end On_Exit;

   procedure On_Quit (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : constant SparGUI.View.Default_View_Access := SparGUI.View.Default_View_Access (Object.Parent.Parent);
      Dummy_Last_View : Gnoga.Gui.View.View_Type;
   begin
      View.Remove;
      Dummy_Last_View.Create (View.Main_Window.all);
      Dummy_Last_View.Put_Line ("SparForte server ended!");
      Gnoga.Application.Multi_Connect.End_Application;
   end On_Quit;

   procedure On_Click (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : constant SparGUI.View.Default_View_Access := SparGUI.View.Default_View_Access (Object.Parent.Parent);
   begin
      View.Label_Text.Put_Line ("Click");
--        gnoga.log(ada.Tags.Expanded_Name(Object.Parent.Parent'tag));
   end On_Click;

   procedure Default
     (Main_Window : in out Gnoga.Gui.Window.Window_Type'Class;
      Connection  :        access Gnoga.Application.Multi_Connect.Connection_Holder_Type)
   is
      pragma Unreferenced (Connection);
      View : constant SparGUI.View.Default_View_Access := new SparGUI.View.Default_View_Type;
   begin
      View.Dynamic;
      View.Main_Window := Main_Window'Unchecked_Access;
      Gnoga.Gui.Plugin.Pixi.Load_PIXI (Main_Window);
      Gnoga.Gui.Plugin.Ace_Editor.Load_Ace_Editor (Main_Window);

--        View.Locale :=
--          ZanyBlue.Text.Locales.Make_Locale_Narrow
--            (Gnoga.Gui.Navigator.Language (Main_Window) & ".ISO8859-1");
--        Main_Window.Document.Title
--        (SparGUI_messages.SparGUI_Strings.Format_TITL (View.Locale));
      Main_Window.Document.Title ("SparForte - GUI (Gnoga)");
--        Gnoga.Server.Connection.HTML_On_Close
--          (Main_Window.Connection_ID,
--           Spar_messages.Spar_Strings.Format_APPE (View.Locale));

--        SparGUI.Parser.Fill (View.Primitives, View.Locale);
      View.Create (Main_Window, Gnoga.Gui.View.Grid.Horizontal_Split);
      --        View.Click_Button.On_Click_Handler (On_Click'Access);
--        Gnoga.Activate_Exception_Handler (Worker'Identity);
      View.Exit_Button.On_Click_Handler (On_Exit'Access);
      View.Quit_Button.On_Click_Handler (On_Quit'Access);
      View.Console_IO.Open (View.Console'Access);
      View.Console_IO.Set_Input;
      View.Console_IO.Set_Output;
      View.Console_IO.Set_Error;
      Spar;  -- Launch SparForte interpreter
   end Default;

begin
   Gnoga.Application.Multi_Connect.On_Connect_Handler (Default'Access, "default");
end SparGUI.Controller;
