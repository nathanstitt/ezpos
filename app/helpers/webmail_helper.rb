require 'cdfutils'
require 'mail2screen'

module WebmailHelper

    include Mail2Screen
    def link_folders
        link_to('Folders', :controller=>"webmail", :action=>"messages")
    end


    def link_refresh
        link_to('Refresh', :controller=>"webmail", :action=>"refresh")
    end

    def link_message_list
        link_to('Message list', :controller=>"webmail", :action=>"messages")
    end

    def link_reply_to_sender(msg_id)
        link_to('Reply', :controller=>"webmail", :action=>"reply", :params=>{"msg_id"=>msg_id})
    end

    def link_forward_message(msg_id)
        link_to('Forward', :controller=>"webmail", :action=>"forward", :params=>{"msg_id"=>msg_id})
    end

    def link_flag_for_deletion(msg_id)
        link_to('Delete', :controller=>"webmail", :action=>"delete", :params=>{"msg_id"=>msg_id})
    end

    def link_view_source(msg_id)
        link_to('View source', {:controller=>"webmail", :action=>"view_source", :params=>{"msg_id"=>msg_id}}, {'target'=>"_blank"})
    end

    def link_manage_folders
        link_to('add/edit', :controller=>"webmail", :action=>"manage_folders")
    end

    def link_back_to_messages
        link_to("&#171;" << 'Back to messages', :controller=>"webmail", :action=>"messages")
    end

    def link_mail_prefs
        link_to('Preferences', :controller=>"webmail", :action=>"prefs")
    end

    def link_mail_filters
        link_to('Filters', :controller=>"webmail", :action=>"filters")
    end

    def link_filter_add
        link_to('Add filter', :controller=>'webmail', :action=>'filter_add')
    end

    def folder_link(folder)
        if folder.attribs.include? :Noselect
            return folder.name
        end

        fn = "#{short_fn(folder)}"
        if folder.name == CDF::CONFIG[:mail_trash]
            link_to( fn,
                     :controller=>'webmail',
                     :action=>"messages",
                     :params=>{"folder_name"=>folder.name} ) \
            << "&nbsp;" \
            << link_to('(Empty)',
                       { :controller=>'webmail',
                           :action=>"empty",
                           :params=>{"folder_name"=>folder.name} },
                       :confirm => 'Do you really want to empty trash?')
        else
            link_to( fn,
                     :controller=>'webmail',
                     :action=>"messages",
                     :params=>{"folder_name"=>folder.name})
        end
    end

    def short_fn(folder)
        if folder.name.include? folder.delim
            "&nbsp; &nbsp;" + folder.name.split(folder.delim).last
        else
            folder.name
        end
    end

    def folder_manage_link(folder)
        if folder.name == CDF::CONFIG[:mail_trash] or folder.name == CDF::CONFIG[:mail_inbox] or folder.name == CDF::CONFIG[:mail_sent]
            short_fn(folder)
        else
            return short_fn(folder) +
                ("&nbsp;" + link_to('(Delete)', :controller=>"webmail", :action=>"manage_folders", :params=>{"op"=>'(Delete)', "folder_name"=>folder.name}))
        end
    end

    def message_date(datestr)
        t = Time.now
        begin
            if datestr.kind_of?(String)
                d = (Time.rfc2822(datestr) rescue Time.parse(value)).localtime
            else
                d = datestr
            end
            if d.day == t.day and d.month == t.month and d.year == t.year
                d.strftime("%H:%M")
            else
                d.strftime("%Y-%m-%d")
            end
        rescue
            begin
                d = imap2time(datestr)
                if d.day == t.day and d.month == t.month and d.year == t.year
                    d.strftime("%H:%M")
                else
                    d.strftime("%Y-%m-%d")
                end
            rescue
                datestr
            end
        end
    end

    def attachment(att, index)
        ret = "#{att.filename}"
        # todo: add link to delete attachment
        #ret <<
        ret << "<input type='hidden' name='att_files[#{index}]' value='#{att.filename}'/>"
        ret << "<input type='hidden' name='att_tfiles[#{index}]' value='#{att.temp_filename}'/>"
        ret << "<input type='hidden' name='att_ctypes[#{index}]' value='#{att.content_type}'/>"
    end

    def link_filter_up(filter_id)
        link_to('Up', :controller=>"webmail", :action=>"filter_up", :id=>filter_id)
    end

    def link_filter_down(filter_id)
        link_to('Down', :controller=>"webmail", :action=>"filter_down", :id=>filter_id)
    end


    def page_navigation_webmail(pages)
        nav = "<p class='paginator'><small>"

        nav << "(#{pages.length} #{'Pages'}) &nbsp; "

        window_pages = pages.current.window.pages
        nav << "..." unless window_pages[0].first?
        for page in window_pages
            if pages.current == page
                nav << page.number.to_s << " "
            else
                nav << link_to(page.number, :controller=>"webmail", :action=>'messages', :page=>page.number) << " "
            end
        end
        nav << "..." unless window_pages[-1].last?
        nav << " &nbsp; "

        nav << link_to('First', :controller=>"webmail", :action=>'messages', :page=>@pages.first.number) << " | " unless @pages.current.first?
        nav << link_to('Prev', :controller=>"webmail", :action=>'messages', :page=>@pages.current.previous.number) << " | " if @pages.current.previous
        nav << link_to('Next', :controller=>"webmail", :action=>'messages', :page=>@pages.current.next.number) << " | " if @pages.current.next
        nav << link_to('Last', :controller=>"webmail", :action=>'messages', :page=>@pages.last.number) << " | " unless @pages.current.last?

        nav << "</small></p>"

        return nav
    end

    def parse_subject(subject)
        begin
            if mime_encoded?(subject)
                if mime_decode(subject) == ''
                    '(No subject)'
                else
                    mime_decode(subject)
                end
            else
                if from_qp(subject) == ''
                    '(No subject)'
                else
                    from_qp(subject)
                end
            end
        rescue Exception => ex
            RAILS_DEFAULT_LOGGER.debug('Exception occured - #{ex}')
            return ""
        end
    end

    def message_size(size)
        if size / (1024*1024) > 0
            return "#{(size / (1024*1024)).round}&nbsp;MB"
        elsif size / 1024 > 0
            return "#{(size / (1024)).round}&nbsp;KB"
        else
            return "#{size}&nbsp;B"
        end
    end
end

