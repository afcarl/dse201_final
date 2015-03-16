'''
Created on Mar 15, 2015

@author: dyerke
'''

from multiprocessing import Process, Value
import time
import traceback
import psycopg2

class StatementExecutorTemplateCallback:
    def __init__(self):
        self._mQuery = self._get_query()
    
    def _get_query(self):
        raise NotImplementedError
    
    def get_description(self):
        return "Executing {}".format(self._mQuery)
    
    def do_in_cursor(self, cur):
        cur.execute(self._mQuery)

class ManagedExecutorTemplateCallback:
    INFINITE = 99999.
    
    def __init__(self, target_callback):
        self._mTargetCallback = target_callback
    
    def execute_target_method(self, cur, duration):
        start = time.time()
        self._mTargetCallback.do_in_cursor(cur)
        end = time.time()
        callback_duration = (end - start) * 1000.
        duration.value = callback_duration
    
    def do_in_cursor(self, cur):
        print self._mTargetCallback.get_description()
        # wait at most 10min
        timeout = 600.0
        #
        duration = Value('f', ManagedExecutorTemplateCallback.INFINITE)
        p = Process(target=self.execute_target_method, args=(cur, duration))
        p.start()
        p.join(timeout)
        if p.is_alive():
            p.terminate()
        return duration.value
    
class StatementExecutorTemplate:
    SIG_DIGITS = 6
    
    def __init__(self, db_name, username, password, hostname, port):
        self._mDbName = db_name
        self._mUsername = username
        self._mPassword = password
        self._mHostname = hostname
        self._mPort = port
    
    def execute(self, callback):
        conn = None
        cur = None
        try:
            conn = psycopg2.connect(database=self._mDbName, user=self._mUsername, password=self._mPassword, host=self._mHostname, port=self._mPort)
            cur = conn.cursor()
            l_wrapped_callback = ManagedExecutorTemplateCallback(callback)
            duration = l_wrapped_callback.do_in_cursor(cur)
            print "duration= {}ms".format(duration)
        except:
            traceback.print_exc()
        finally:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()

class InternalStatesCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        return "select * from sales"

class InternalTotalSalesForEachCustomerCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        statement = """
        SELECT users.name as customer_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
        FROM users, sales
        WHERE users.id = sales.uid
        GROUP BY users.name
        """
        return statement

class InternalTotalSalesForEachStateCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        statement = """
        SELECT states.name as state_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
        FROM sales, users, states
        WHERE sales.uid = users.id AND
                users.state = states.id
        GROUP BY states.name
        """
        return statement

class InternalTotalSalesForAGivenCustomerCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        statement = """
        SELECT products.sku as product_sku, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
        FROM sales, products, users
        WHERE   users.name = 'user_1' AND
                sales.uid = users.id AND
                products.id = sales.pid
        GROUP BY products.sku
        ORDER BY dollar_value
        """
        return statement

class InternalTotalSalesForEachProductCustomerCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        statement = """
        SELECT products.sku as product_sku, users.name as customer, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
        FROM sales, products, users
        WHERE sales.uid = users.id AND 
            products.id = sales.pid
        GROUP BY products.sku, users.name
        ORDER BY dollar_value
        """
        return statement

class InternalTotalSalesForEachCategoryAndStateCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        statement = """
        SELECT states.name as state_name, categories.name as category_name, sum(sales.quantity) as total_quantity, sum(sales.price) as dollar_value
        FROM sales, products, users, categories, states
        WHERE sales.uid = users.id AND
            users.state = states.id AND
            products.id = sales.pid AND
            categories.id = products.cid
        GROUP BY states.name, categories.name
        """
        return statement

class InternalTotalSalesForTop20CategoriesAndCustomersCallback(StatementExecutorTemplateCallback):
    def _get_query(self):
        statement = """
        with top_20_categories as (
        select c.id as category_id, c.name as category_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
        from sales as s
        inner join products as p on s.pid=p.id
        inner join categories as c on p.cid=c.id
        group by c.id, c.name
        order by dollar_value desc
        limit 20
        ), top_20_customers as (
        select u.id as customer_id, u.name as customer_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
        from sales as s
        inner join users as u on s.uid=u.id
        group by u.id, u.name
        order by dollar_value desc
        limit 20
        )
        select tcat.category_name as top_category, tc.customer_name as top_customer, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
        from sales s
        inner join products as p on s.pid=p.id
        inner join top_20_categories as tcat on p.cid=tcat.category_id
        inner join top_20_customers as tc on s.uid=tc.customer_id
        group by tcat.category_name, tc.customer_name
        order by dollar_value desc
        """
        return statement

if __name__ == '__main__':
    db_name = 'dyerke'
    username = 'dyerke'
    password = 'dyerke'
    hostname = 'localhost'
    port = 5432
    
    
    template = StatementExecutorTemplate(db_name, username, password, hostname, port)
    callbacks = [InternalTotalSalesForEachCustomerCallback,
        InternalTotalSalesForEachStateCallback,
        InternalTotalSalesForAGivenCustomerCallback,
        InternalTotalSalesForEachProductCustomerCallback,
        InternalTotalSalesForEachCategoryAndStateCallback,
        InternalTotalSalesForTop20CategoriesAndCustomersCallback 
    ]
    for c in callbacks:
        l_callback = c()
        template.execute(l_callback)
        print '\n'
