import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;

public class NamazuHistory extends Frame implements
  ActionListener, ItemListener {
  MenuBar mbar_hist;
  Menu file_hist_menu;
  MenuItem file_hist_quit;
  List hist_list_area;
  TextField select_list_area, tf;
  Button b_ok, b_clear;
  Panel p0;

  ResourceBundle namazuResources =
    ResourceBundle.getBundle ("NamazuResources");

  public void init () {
	mbar_hist = new MenuBar ();
	setMenuBar (mbar_hist);

	file_hist_menu = new Menu (namazuResources.getString ("FILE"));
	mbar_hist.add (file_hist_menu);
	file_hist_quit = new MenuItem (namazuResources.getString ("Quit"));
	file_hist_quit.addActionListener (this);
	file_hist_menu.add (file_hist_quit);

	hist_list_area = new List (10, false);
	hist_list_area.setBackground (Color.white);
	hist_list_area.addActionListener (this);
	hist_list_area.addItemListener (this);

	b_ok = new Button (namazuResources.getString ("OK"));
	b_clear = new Button (namazuResources.getString ("Clear"));
	b_ok.addActionListener (this);
	b_clear.addActionListener (this);
	p0 = new Panel ();
	p0.add (b_ok);
	p0.add (b_clear);

	setLayout (new BorderLayout ());
	add ("North", hist_list_area);
	select_list_area = new TextField (30);
	select_list_area.setBackground (Color.white);
	add ("Center", select_list_area);
	add ("South", p0);

	setTitle (namazuResources.getString ("History"));
  }
  public void ItemEvent (ItemEvent ie) {}

  public void itemStateChanged (ItemEvent ie) {
	select_list_area.setText (hist_list_area.getSelectedItem ());
  }

  public void actionPerformed (ActionEvent ae) {
	if (ae.getSource () == file_hist_quit) {
	  Namazu.first_hist = true;
	  setVisible (false);
	  //	  dispose (); // Bug? 二回目以降、メニューバーが表示されない。
	  return;
	} else if (ae.getSource () == b_ok) {
	  tf.setText (select_list_area.getText ());
	} else if (ae.getSource () == hist_list_area) {
	  select_list_area.setText (hist_list_area.getSelectedItem ());
	} else if (ae.getSource () == b_clear) {
	  select_list_area.setText ("");
	}
  }

  public static void main (String args []) {
  NamazuHistory namazuhist_window = new NamazuHistory ();
  namazuhist_window.init ();
  namazuhist_window.pack ();
  namazuhist_window.show ();
  }
  public void settf (TextField tf) {
	this.tf = tf;
  }

  public void addhistory (String histlist) {
	this.hist_list_area.add (histlist);
  }
}
