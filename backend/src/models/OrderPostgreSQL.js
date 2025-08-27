// ========================================
// ORDER MODEL - POSTGRESQL - PHASE 4
// Gestion complète des commandes marketplace
// ========================================

const databaseHybridService = require('../services/database-hybrid.service');

class OrderPostgreSQL {
  constructor() {
    this.tableName = 'orders';
    this.init();
  }

  // ========================================
  // INITIALIZATION
  // ========================================
  
  async init() {
    try {
      await this.createTables();
      console.log('✅ Orders tables initialized');
    } catch (error) {
      console.error('❌ Error initializing orders tables:', error);
    }
  }

  async createTables() {
    // Orders table
    const createOrdersTable = `
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
        order_number VARCHAR(50) UNIQUE NOT NULL,
        
        -- Customer information
        customer_id INTEGER NOT NULL REFERENCES users(id),
        customer_email VARCHAR(255) NOT NULL,
        customer_name VARCHAR(255) NOT NULL,
        customer_phone VARCHAR(20),
        
        -- Shipping information
        shipping_address JSONB NOT NULL,
        billing_address JSONB NOT NULL,
        shipping_method VARCHAR(50) DEFAULT 'standard',
        shipping_cost DECIMAL(10,2) DEFAULT 0.00,
        estimated_delivery DATE,
        
        -- Order details
        subtotal DECIMAL(10,2) NOT NULL,
        tax_amount DECIMAL(10,2) DEFAULT 0.00,
        discount_amount DECIMAL(10,2) DEFAULT 0.00,
        total_amount DECIMAL(10,2) NOT NULL,
        currency VARCHAR(3) DEFAULT 'EUR',
        
        -- Payment information
        payment_method VARCHAR(50) NOT NULL,
        payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded', 'partially_refunded')),
        payment_intent_id VARCHAR(255),
        stripe_charge_id VARCHAR(255),
        
        -- Order status
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')),
        status_history JSONB DEFAULT '[]',
        
        -- Marketplace specific
        commission_amount DECIMAL(10,2) DEFAULT 0.00,
        vendor_payout_amount DECIMAL(10,2) DEFAULT 0.00,
        
        -- Timestamps
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        paid_at TIMESTAMP,
        shipped_at TIMESTAMP,
        delivered_at TIMESTAMP,
        cancelled_at TIMESTAMP
      );
    `;

    // Order items table
    const createOrderItemsTable = `
      CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        product_id VARCHAR(255) NOT NULL,
        product_name VARCHAR(255) NOT NULL,
        product_sku VARCHAR(100),
        product_image TEXT,
        
        -- Pricing
        unit_price DECIMAL(10,2) NOT NULL,
        quantity INTEGER NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        
        -- Vendor information
        vendor_id INTEGER NOT NULL REFERENCES users(id),
        vendor_name VARCHAR(255) NOT NULL,
        commission_rate DECIMAL(5,2) DEFAULT 3.50,
        commission_amount DECIMAL(10,2) DEFAULT 0.00,
        
        -- Item status
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded')),
        
        -- Timestamps
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // Order status history table
    const createOrderStatusHistoryTable = `
      CREATE TABLE IF NOT EXISTS order_status_history (
        id SERIAL PRIMARY KEY,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        status VARCHAR(20) NOT NULL,
        previous_status VARCHAR(20),
        notes TEXT,
        updated_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // Vendor payouts table
    const createVendorPayoutsTable = `
      CREATE TABLE IF NOT EXISTS vendor_payouts (
        id SERIAL PRIMARY KEY,
        vendor_id INTEGER NOT NULL REFERENCES users(id),
        order_id INTEGER NOT NULL REFERENCES orders(id),
        order_item_id INTEGER NOT NULL REFERENCES order_items(id),
        
        -- Payout details
        gross_amount DECIMAL(10,2) NOT NULL,
        commission_amount DECIMAL(10,2) NOT NULL,
        net_amount DECIMAL(10,2) NOT NULL,
        payout_status VARCHAR(20) DEFAULT 'pending' CHECK (payout_status IN ('pending', 'processing', 'paid', 'failed')),
        
        -- Stripe Connect
        stripe_transfer_id VARCHAR(255),
        stripe_account_id VARCHAR(255),
        
        -- Timestamps
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        paid_at TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // Create all tables
    await databaseHybridService.queryPostgreSQL(createOrdersTable);
    await databaseHybridService.queryPostgreSQL(createOrderItemsTable);
    await databaseHybridService.queryPostgreSQL(createOrderStatusHistoryTable);
    await databaseHybridService.queryPostgreSQL(createVendorPayoutsTable);

    // Create indexes
    const createIndexes = `
      -- Orders indexes
      CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
      CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
      CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
      CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
      CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
      
      -- Order items indexes
      CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
      CREATE INDEX IF NOT EXISTS idx_order_items_vendor_id ON order_items(vendor_id);
      CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
      
      -- Status history indexes
      CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
      CREATE INDEX IF NOT EXISTS idx_order_status_history_status ON order_status_history(status);
      
      -- Vendor payouts indexes
      CREATE INDEX IF NOT EXISTS idx_vendor_payouts_vendor_id ON vendor_payouts(vendor_id);
      CREATE INDEX IF NOT EXISTS idx_vendor_payouts_order_id ON vendor_payouts(order_id);
      CREATE INDEX IF NOT EXISTS idx_vendor_payouts_status ON vendor_payouts(payout_status);
    `;

    await databaseHybridService.queryPostgreSQL(createIndexes);

    // Create triggers
    const createTriggers = `
      -- Trigger for updated_at
      CREATE OR REPLACE FUNCTION update_orders_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
      
      CREATE TRIGGER IF NOT EXISTS update_orders_updated_at 
        BEFORE UPDATE ON orders 
        FOR EACH ROW 
        EXECUTE FUNCTION update_orders_updated_at();
      
      -- Trigger for order items updated_at
      CREATE OR REPLACE FUNCTION update_order_items_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
      
      CREATE TRIGGER IF NOT EXISTS update_order_items_updated_at 
        BEFORE UPDATE ON order_items 
        FOR EACH ROW 
        EXECUTE FUNCTION update_order_items_updated_at();
      
      -- Trigger for vendor payouts updated_at
      CREATE OR REPLACE FUNCTION update_vendor_payouts_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
      
      CREATE TRIGGER IF NOT EXISTS update_vendor_payouts_updated_at 
        BEFORE UPDATE ON vendor_payouts 
        FOR EACH ROW 
        EXECUTE FUNCTION update_vendor_payouts_updated_at();
    `;

    await databaseHybridService.queryPostgreSQL(createTriggers);
  }

  // ========================================
  // ORDER CRUD OPERATIONS
  // ========================================
  
  async createOrder(orderData) {
    const {
      customerId,
      customerEmail,
      customerName,
      customerPhone,
      shippingAddress,
      billingAddress,
      shippingMethod = 'standard',
      shippingCost = 0.00,
      items,
      paymentMethod,
      currency = 'EUR'
    } = orderData;

    // Validate required fields
    if (!customerId || !customerEmail || !customerName || !shippingAddress || !billingAddress || !items || !paymentMethod) {
      throw new Error('Missing required order fields');
    }

    if (!Array.isArray(items) || items.length === 0) {
      throw new Error('Order must contain at least one item');
    }

    // Calculate totals
    const subtotal = items.reduce((sum, item) => sum + (item.unitPrice * item.quantity), 0);
    const taxAmount = subtotal * 0.20; // 20% VAT for France
    const totalAmount = subtotal + taxAmount + shippingCost;

    // Generate order number
    const orderNumber = this.generateOrderNumber();

    return await databaseHybridService.withTransaction(async (client) => {
      // Create order
      const orderSQL = `
        INSERT INTO orders (
          order_number, customer_id, customer_email, customer_name, customer_phone,
          shipping_address, billing_address, shipping_method, shipping_cost,
          subtotal, tax_amount, total_amount, currency, payment_method
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING *
      `;

      const orderValues = [
        orderNumber,
        customerId,
        customerEmail,
        customerName,
        customerPhone,
        JSON.stringify(shippingAddress),
        JSON.stringify(billingAddress),
        shippingMethod,
        shippingCost,
        subtotal,
        taxAmount,
        totalAmount,
        currency,
        paymentMethod
      ];

      const orderResult = await client.query(orderSQL, orderValues);
      const order = orderResult.rows[0];

      // Create order items
      const orderItems = [];
      let totalCommission = 0;

      for (const item of items) {
        const itemSQL = `
          INSERT INTO order_items (
            order_id, product_id, product_name, product_sku, product_image,
            unit_price, quantity, total_price, vendor_id, vendor_name,
            commission_rate, commission_amount
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
          RETURNING *
        `;

        const commissionAmount = (item.totalPrice * item.commissionRate) / 100;
        totalCommission += commissionAmount;

        const itemValues = [
          order.id,
          item.productId,
          item.productName,
          item.productSku || null,
          item.productImage || null,
          item.unitPrice,
          item.quantity,
          item.totalPrice,
          item.vendorId,
          item.vendorName,
          item.commissionRate || 3.50,
          commissionAmount
        ];

        const itemResult = await client.query(itemSQL, itemValues);
        orderItems.push(itemResult.rows[0]);

        // Create vendor payout record
        const payoutSQL = `
          INSERT INTO vendor_payouts (
            vendor_id, order_id, order_item_id, gross_amount,
            commission_amount, net_amount
          ) VALUES ($1, $2, $3, $4, $5, $6)
        `;

        const payoutValues = [
          item.vendorId,
          order.id,
          itemResult.rows[0].id,
          item.totalPrice,
          commissionAmount,
          item.totalPrice - commissionAmount
        ];

        await client.query(payoutSQL, payoutValues);
      }

      // Update order with commission
      const updateOrderSQL = `
        UPDATE orders 
        SET commission_amount = $1, vendor_payout_amount = $2
        WHERE id = $3
      `;

      await client.query(updateOrderSQL, [totalCommission, totalAmount - totalCommission, order.id]);

      // Add initial status to history
      const statusHistorySQL = `
        INSERT INTO order_status_history (order_id, status, notes)
        VALUES ($1, 'pending', 'Order created')
      `;

      await client.query(statusHistorySQL, [order.id]);

      return {
        ...order,
        items: orderItems
      };
    });
  }

  async getOrderById(id) {
    const orderSQL = `
      SELECT * FROM orders WHERE id = $1
    `;

    const itemsSQL = `
      SELECT * FROM order_items WHERE order_id = $1
    `;

    const statusHistorySQL = `
      SELECT * FROM order_status_history 
      WHERE order_id = $1 
      ORDER BY created_at DESC
    `;

    const [orderResult, itemsResult, statusResult] = await Promise.all([
      databaseHybridService.queryPostgreSQL(orderSQL, [id]),
      databaseHybridService.queryPostgreSQL(itemsSQL, [id]),
      databaseHybridService.queryPostgreSQL(statusHistorySQL, [id])
    ]);

    if (orderResult.rows.length === 0) {
      return null;
    }

    const order = orderResult.rows[0];
    order.items = itemsResult.rows;
    order.statusHistory = statusResult.rows;

    return order;
  }

  async getOrderByNumber(orderNumber) {
    const sql = `
      SELECT * FROM orders WHERE order_number = $1
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [orderNumber]);
    return result.rows[0] || null;
  }

  async getOrdersByCustomer(customerId, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const sql = `
      SELECT o.*, 
             COUNT(*) OVER() as total_count,
             ARRAY_AGG(oi.id) as item_ids
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.customer_id = $1
      GROUP BY o.id
      ORDER BY o.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [customerId, limit, offset]);
    
    const orders = result.rows.map(row => {
      const order = { ...row };
      delete order.item_ids;
      delete order.total_count;
      return order;
    });

    const totalCount = result.rows[0]?.total_count || 0;

    return {
      orders,
      pagination: {
        page,
        limit,
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    };
  }

  async getOrdersByVendor(vendorId, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const sql = `
      SELECT o.*, 
             oi.product_name, oi.product_image, oi.quantity, oi.total_price,
             oi.commission_amount, oi.status as item_status,
             COUNT(*) OVER() as total_count
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      WHERE oi.vendor_id = $1
      ORDER BY o.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [vendorId, limit, offset]);
    
    const orders = result.rows.map(row => {
      const order = { ...row };
      delete order.total_count;
      return order;
    });

    const totalCount = result.rows[0]?.total_count || 0;

    return {
      orders,
      pagination: {
        page,
        limit,
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    };
  }

  // ========================================
  // ORDER STATUS MANAGEMENT
  // ========================================
  
  async updateOrderStatus(orderId, newStatus, notes = '', updatedBy = null) {
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'];
    
    if (!validStatuses.includes(newStatus)) {
      throw new Error('Invalid order status');
    }

    return await databaseHybridService.withTransaction(async (client) => {
      // Get current status
      const currentOrderSQL = 'SELECT status FROM orders WHERE id = $1';
      const currentOrderResult = await client.query(currentOrderSQL, [orderId]);
      
      if (currentOrderResult.rows.length === 0) {
        throw new Error('Order not found');
      }

      const currentStatus = currentOrderResult.rows[0].status;

      // Update order status
      const updateOrderSQL = `
        UPDATE orders 
        SET status = $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
        RETURNING *
      `;

      const updateResult = await client.query(updateOrderSQL, [newStatus, orderId]);
      const order = updateResult.rows[0];

      // Add status to history
      const historySQL = `
        INSERT INTO order_status_history (
          order_id, status, previous_status, notes, updated_by
        ) VALUES ($1, $2, $3, $4, $5)
      `;

      await client.query(historySQL, [orderId, newStatus, currentStatus, notes, updatedBy]);

      // Update specific timestamps based on status
      if (newStatus === 'paid') {
        await client.query('UPDATE orders SET paid_at = CURRENT_TIMESTAMP WHERE id = $1', [orderId]);
      } else if (newStatus === 'shipped') {
        await client.query('UPDATE orders SET shipped_at = CURRENT_TIMESTAMP WHERE id = $1', [orderId]);
      } else if (newStatus === 'delivered') {
        await client.query('UPDATE orders SET delivered_at = CURRENT_TIMESTAMP WHERE id = $1', [orderId]);
      } else if (newStatus === 'cancelled') {
        await client.query('UPDATE orders SET cancelled_at = CURRENT_TIMESTAMP WHERE id = $1', [orderId]);
      }

      return order;
    });
  }

  // ========================================
  // PAYMENT MANAGEMENT
  // ========================================
  
  async updatePaymentStatus(orderId, paymentStatus, paymentIntentId = null, stripeChargeId = null) {
    const validPaymentStatuses = ['pending', 'paid', 'failed', 'refunded', 'partially_refunded'];
    
    if (!validPaymentStatuses.includes(paymentStatus)) {
      throw new Error('Invalid payment status');
    }

    const sql = `
      UPDATE orders 
      SET payment_status = $1, 
          payment_intent_id = $2,
          stripe_charge_id = $3,
          updated_at = CURRENT_TIMESTAMP,
          paid_at = CASE WHEN $1 = 'paid' THEN CURRENT_TIMESTAMP ELSE paid_at END
      WHERE id = $4
      RETURNING *
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [
      paymentStatus, 
      paymentIntentId, 
      stripeChargeId, 
      orderId
    ]);

    if (result.rows.length === 0) {
      throw new Error('Order not found');
    }

    return result.rows[0];
  }

  // ========================================
  // VENDOR PAYOUTS
  // ========================================
  
  async getVendorPayouts(vendorId, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const sql = `
      SELECT vp.*, o.order_number, oi.product_name, oi.quantity
      FROM vendor_payouts vp
      JOIN orders o ON vp.order_id = o.id
      JOIN order_items oi ON vp.order_item_id = oi.id
      WHERE vp.vendor_id = $1
      ORDER BY vp.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [vendorId, limit, offset]);
    return result.rows;
  }

  async updatePayoutStatus(payoutId, status, stripeTransferId = null) {
    const sql = `
      UPDATE vendor_payouts 
      SET payout_status = $1, 
          stripe_transfer_id = $2,
          paid_at = CASE WHEN $1 = 'paid' THEN CURRENT_TIMESTAMP ELSE paid_at END,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING *
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [status, stripeTransferId, payoutId]);
    
    if (result.rows.length === 0) {
      throw new Error('Payout not found');
    }

    return result.rows[0];
  }

  // ========================================
  // ANALYTICS & REPORTING
  // ========================================
  
  async getOrderAnalytics(vendorId = null, startDate = null, endDate = null) {
    let sql = `
      SELECT 
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as average_order_value,
        SUM(commission_amount) as total_commission,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders
      FROM orders
    `;

    const values = [];
    let paramCount = 1;

    if (vendorId) {
      sql += ` WHERE id IN (SELECT DISTINCT order_id FROM order_items WHERE vendor_id = $${paramCount})`;
      values.push(vendorId);
      paramCount++;
    }

    if (startDate) {
      sql += vendorId ? ' AND' : ' WHERE';
      sql += ` created_at >= $${paramCount}`;
      values.push(startDate);
      paramCount++;
    }

    if (endDate) {
      sql += ' AND';
      sql += ` created_at <= $${paramCount}`;
      values.push(endDate);
      paramCount++;
    }

    const result = await databaseHybridService.queryPostgreSQL(sql, values);
    return result.rows[0];
  }

  // ========================================
  // UTILITY METHODS
  // ========================================
  
  generateOrderNumber() {
    const timestamp = Date.now().toString();
    const random = Math.random().toString(36).substr(2, 5).toUpperCase();
    return `ORD-${timestamp}-${random}`;
  }

  async searchOrders(query, filters = {}, page = 1, limit = 20) {
    let sql = `
      SELECT DISTINCT o.*, 
             COUNT(*) OVER() as total_count
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE 1=1
    `;

    const values = [];
    let paramCount = 1;

    // Search query
    if (query) {
      sql += ` AND (
        o.order_number ILIKE $${paramCount} OR 
        o.customer_name ILIKE $${paramCount} OR 
        o.customer_email ILIKE $${paramCount} OR
        oi.product_name ILIKE $${paramCount}
      )`;
      values.push(`%${query}%`);
      paramCount++;
    }

    // Status filter
    if (filters.status) {
      sql += ` AND o.status = $${paramCount}`;
      values.push(filters.status);
      paramCount++;
    }

    // Payment status filter
    if (filters.paymentStatus) {
      sql += ` AND o.payment_status = $${paramCount}`;
      values.push(filters.paymentStatus);
      paramCount++;
    }

    // Date range filter
    if (filters.startDate) {
      sql += ` AND o.created_at >= $${paramCount}`;
      values.push(filters.startDate);
      paramCount++;
    }

    if (filters.endDate) {
      sql += ` AND o.created_at <= $${paramCount}`;
      values.push(filters.endDate);
      paramCount++;
    }

    // Pagination
    const offset = (page - 1) * limit;
    sql += ` ORDER BY o.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(limit, offset);

    const result = await databaseHybridService.queryPostgreSQL(sql, values);
    
    const orders = result.rows.map(row => {
      const order = { ...row };
      delete order.total_count;
      return order;
    });

    const totalCount = result.rows[0]?.total_count || 0;

    return {
      orders,
      pagination: {
        page,
        limit,
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    };
  }
}

module.exports = new OrderPostgreSQL();
