require 'cdfutils'
require 'mail2screen'

module ApiHelper
  include Mail2Screen
  include WebmailHelper
  def page_navigation_api(pages)
    nav = "<p class='paginator'><small>"
    
    nav << "(#{pages.length} #{_('Pages')}) &nbsp; "
    
    window_pages = pages.current.window.pages
    nav << "..." unless window_pages[0].first?
    for page in window_pages
      if pages.current == page
        nav << page.number.to_s << " "
      else
        nav << link_to(page.number, :controller=>"api", :action=>'messages', :page=>page.number) << " "
      end
    end
    nav << "..." unless window_pages[-1].last?
    nav << " &nbsp; "
    
    nav << link_to(_('First'), :controller=>"api", :action=>'messages', :page=>@pages.first.number) << " | " unless @pages.current.first?
    nav << link_to(_('Prev'), :controller=>"api", :action=>'messages', :page=>@pages.current.previous.number) << " | " if @pages.current.previous
    nav << link_to(_('Next'), :controller=>"api", :action=>'messages', :page=>@pages.current.next.number) << " | " if @pages.current.next
    nav << link_to(_('Last'), :controller=>"api", :action=>'messages', :page=>@pages.last.number) << " | " unless @pages.current.last?
    
    nav << "</small></p>"
    
    return nav
  end
end
