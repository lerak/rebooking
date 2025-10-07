class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = Customer.all
  end

  def show
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    @customer.business = current_user.business

    if @customer.save
      redirect_to @customer, notice: 'Customer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: 'Customer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_url, notice: 'Customer was successfully deleted.'
  end

  private

  def set_customer
    @customer = current_user.business.customers.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :phone, :email)
  end
end
