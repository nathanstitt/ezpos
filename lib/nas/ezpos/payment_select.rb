module NAS

module EZPOS

class PaymentSelect < Gtk::Dialog
    MARKUP='<span weight="bold" foreground="red" size="large">'

    attr_reader :payment

    def initialize( sale, remaining )
        super()
        self.title = 'Select Payment Type/Amount'
        self.modal=true
        @sale=sale
        @types=Hash.new
        @current_boxes=Array.new


        label = Gtk::Label.new
        if sale.total == remaining
            label.markup="#{MARKUP}#{sale.total.format}</span>"
        else
            label.markup="#{MARKUP}#{sale.total.format} - #{(sale.total-remaining).format} = #{remaining.format}</span>"
        end
        vbox.pack_start( label, false )

        self.default_response=Gtk::Dialog::RESPONSE_OK

        buttons=Gtk::HBox.new
        vbox.pack_start( buttons, false, false, 5 )

        group=Gtk::RadioButton.new
        num=1
        methods=PosPayment.non_credit_card
        if Settings['proccess_credit_cards']
            methods << PosPayment::CreditCard
        else
            methods << PosPayment::CreditCardTerminal
        end
        methods.each do | pt |
            button=Gtk::RadioButton.new( group,"F#{num}-#{pt.name.demodulize.titleize}" )
            alt_s = Gtk::AccelGroup.new
            alt_s.connect( Gdk::Keyval.const_get( "GDK_F#{num}".to_sym),nil, Gtk::ACCEL_VISIBLE ) {
                button.activate
                self.set_inputs( pt )
            }
            @types[ pt ] = button
            self.add_accel_group( alt_s )
            num+=1
            buttons.add( button )
            button.signal_connect('clicked') do |button|
                self.set_inputs( pt )
            end
        end

        hbox=Gtk::HBox.new
        vbox.pack_start(hbox,false,false,5)
        hbox.pack_start( Gtk::Label.new( 'Amount: ' ),false )
        @amount_entry=Gtk::Entry.new
        @amount_entry.activates_default=true
        @amount_entry.text=remaining.money
        hbox.pack_start( @amount_entry,true,true )

        @ok=false

        self.add_button( Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL )

        btn=self.add_button( Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK )
        btn.grab_default

        signal_connect("response") do |widget, response|
            got_response( response )
        end
        show_all

        @types[PosPayment::Cash].activate
        self.run
    end

    def got_response( resp )
        if ( @payment == PosPayment::CreditCard && PosPayment::CreditCard.is_bad_swipe?( custom_input_values.first ) )
            Gdk::Display.default.beep
            @current_boxes.each{ |bx| bx.text="" }
        end
        if resp ==  Gtk::Dialog::RESPONSE_OK
            RAILS_DEFAULT_LOGGER.info "SALE #{@sale.id} had payment type #{payment.name} selected"

            @payment.data=custom_input_values.first

            if @payment.valid?

                if payment.is_a?( PosPayment::CreditCard )
                    ccp=CreditCardPayment.new( custom_input_values, @amount_entry.text )
                    if ccp.ok?
                        @payment.cc_digits = ccp.cc_number[ ccp.cc_number.length-4..ccp.cc_number.length  ]
                        @payment.data = ccp.msg
                        finished_ok
                    else
                        show_errors( [ "Credit Card Failed to process.\nMsg Returned:\n#{ccp.msg}" ] )

                    end
                elsif payment.is_a?( PosPayment::Billing )
                    cust_info = CustomerInfoDialog.new( payment.customer )
                    if cust_info.ok?
                        finished_ok
                    else
                        self.run
                    end
                else
                    finished_ok
                end
            else
                err=[]
                @payment.errors.each{|el,msg| err << msg }
                show_errors( err )
            end
        else
            @ok=false
            self.destroy
        end
    end

    def finished_ok
        @payment.amount=BigDecimal.new( @amount_entry.text )
        @payment.save!
        @ok=true
        self.destroy
    end

    def show_errors(errors)
        dialog = Gtk::MessageDialog.new( nil,Gtk::Dialog::MODAL,
                                         Gtk::MessageDialog::ERROR,
                                         Gtk::MessageDialog::BUTTONS_OK,
                                         errors.join("\n") )
        ret = ( dialog.run == Gtk::Dialog::RESPONSE_OK )
        dialog.destroy
        self.run
    end

    def ok?
        @ok
    end


    def transaction_id=( trans )
        @transaction_id = trans
    end

    def custom_input_values
        ret=Array.new
        @current_boxes.each{ | el | ret << el.last.text }
        ret
    end

    def set_inputs( pt )
        @payment=pt.new
        @payment.sale = @sale

        @current_boxes.each do | ( box, label, entry ) |
            self.vbox.remove( box )
        end
        @current_boxes.clear
        pt.needs.each do | need |
            box=Gtk::HBox.new
            label=Gtk::Label.new( need )
            entry=Gtk::Entry.new
            entry.activates_default=true
            @current_boxes <<  Array[ box, label, entry ]
            self.vbox.pack_start( box )
            box.pack_start( label,false )
            box.pack_start( entry,true,true,5 )
            box.show_all
        end
        need=@current_boxes.first
        need.last.grab_focus unless need.nil?
    end


end # PaymentSelect

end # EZPOS

end # NAS
