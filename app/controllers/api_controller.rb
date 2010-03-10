require 'cdfmail'
require 'net/smtp'
require 'net/imap'
require 'mail2screen'
require 'ezcrypto'

class ApiController < ApplicationController
  include ImapUtils
  # Administrative functions
  before_filter :login_required
  
  before_filter :obtain_cookies_for_search_and_nav
    
  before_filter :load_imap_session
  
  after_filter :close_imap_session
  
  def message
    @folder_name = params[:contact]
    @folder_name ||= 'INBOX'
    @msg_id = msg_id_param
    @imapmail = folder.message(@msg_id)
    # folder.mark_read(@imapmail.uid) if @imapmail.unread
    @mail = TMail::Mail.parse(@imapmail.full_body)
    render :partial => 'message'
  end
  
  def messages
    @folder_name = params[:contact]
    @folder_name ||= 'INBOX'
    session["return_to"] = nil
    @search_field = params['search_field']
    @search_value = params['search_value']
    
    # handle sorting - tsort session field contains last reverse or no for field
    # and lsort - last sort field
    if session['tsort'].nil? or session['lsort'].nil?
      session['lsort'] = "DATE"
      session['tsort'] = {"DATE" => true, "FROM" => true, "SUBJECT" => true, "TO" => false}
    end
    
    case operation_param
    when _('copy') # copy
      msg_ids = []
      messages_param.each { |msg_id, bool| 
        msg_ids << msg_id.to_i if bool == BOOL_ON and dst_folder != @folder_name }  if messages_param
      folder.copy_multiple(msg_ids, dst_folder) if msg_ids.size > 0 
    when _('move') # move
      msg_ids = []
      messages_param.each { |msg_id, bool| 
        msg_ids << msg_id.to_i if bool == BOOL_ON and dst_folder != @folder_name } if messages_param
      folder.move_multiple(msg_ids, dst_folder) if msg_ids.size > 0 
    when _('delete') # delete
      msg_ids = []
      messages_param.each { |msg_id, bool| msg_ids << msg_id.to_i if bool == BOOL_ON } if messages_param
      folder.delete_multiple(msg_ids) if msg_ids.size > 0
    when _('mark read') # mark as read
      messages_param.each { |msg_id, bool| msg = folder.mark_read(msg_id.to_i) if bool == BOOL_ON }  if messages_param
    when _('mark unread') # mark as unread
      messages_param.each { |msg_id, bool| msg = folder.mark_unread(msg_id.to_i) if bool == BOOL_ON }  if messages_param
    when "SORT"
      session['lsort'] = sort_query = params["scc"]
      session['tsort'][sort_query] = (session['tsort'][sort_query]? false : true)
      @search_field, @search_value = session['search_field'], session['search_value']
    when _('Search') # search  
      session['search_field'] = @search_field
      session['search_value'] = @search_value
    when _('Show all') # search  
      session['search_field'] = @search_field = nil
      session['search_value'] = @search_value = nil
    else
      # get search criteria from session
      @search_field = session['search_field']
      @search_value = session['search_value']
    end
    
    sort_query = session['lsort']
    reverse_sort = session['tsort'][sort_query]
    query = ["ALL"]
    @page = params["page"]
    @page ||= session['page']
    session['page'] = @page
    if @search_field and @search_value and not(@search_field.strip() == "") and not(@search_value.strip() == "")
      @pages = Paginator.new self, 0, get_mail_prefs.wm_rows, @page
      @messages = folder.messages_search([@search_field, @search_value], sort_query + (reverse_sort ? ' desc' : ' asc'))
    else
      @pages = Paginator.new self, folder.total, get_mail_prefs.wm_rows, @page
      @messages = folder.messages(@pages.current.first_item - 1, get_mail_prefs.wm_rows, sort_query + (reverse_sort ? ' desc' : ' asc'))
    end
    render :partial => 'messages'
    
  end
  def obtain_cookies_for_search_and_nav
    @srch_class = ((cookies['_wmlms'] and cookies['_wmlms'] == 'closed') ? 'closed' : 'open')
    @srch_img_src = ((cookies['_wmlms'] and cookies['_wmlms'] == 'closed') ? 'closed' : 'opened') 
    @ops_class = ((cookies['_wmlmo'] and cookies['_wmlmo'] == 'closed') ? 'closed' : 'open')
    @ops_img_src = ((cookies['_wmlmo'] and cookies['_wmlmo'] == 'closed') ? 'closed' : 'opened')     
  end  
  
  ###################################################################
  ### Some fixed parameters and session variables
  ###################################################################
  def folder
    @folders[@folder_name]
  end
  
  def msg_id_param
    params["msg_id"]
  end
  
  def messages_param
    params["messages"]
  end
  
  def dst_folder
    params["cpdest"]
  end
  
  def operation_param
    params["op"]
  end
end
