const structuredLogger = require('./structured-logger.service');

class PaginationService {
  constructor() {
    this.defaultLimit = 20;
    this.maxLimit = 100;
    this.defaultSort = '-createdAt';
  }

  /**
   * Paginate MongoDB queries with optimization
   * @param {Object} model - Mongoose model
   * @param {Object} query - MongoDB query
   * @param {Object} options - Pagination options
   * @returns {Promise<Object>} Paginated result
   */
  async paginate(model, query = {}, options = {}) {
    try {
      const {
        page = 1,
        limit = this.defaultLimit,
        sort = this.defaultSort,
        select = '',
        populate = '',
        lean = true,
        allowDiskUse = false
      } = options;

      // Validate and sanitize inputs
      const sanitizedPage = Math.max(1, parseInt(page));
      const sanitizedLimit = Math.min(this.maxLimit, Math.max(1, parseInt(limit)));
      const skip = (sanitizedPage - 1) * sanitizedLimit;

      // Build query
      let mongoQuery = model.find(query);

      // Apply select fields
      if (select) {
        mongoQuery = mongoQuery.select(select);
      }

      // Apply populate
      if (populate) {
        if (Array.isArray(populate)) {
          populate.forEach(pop => {
            mongoQuery = mongoQuery.populate(pop);
          });
        } else {
          mongoQuery = mongoQuery.populate(populate);
        }
      }

      // Apply sorting
      if (sort) {
        mongoQuery = mongoQuery.sort(sort);
      }

      // Apply pagination
      mongoQuery = mongoQuery.skip(skip).limit(sanitizedLimit);

      // Apply lean for performance
      if (lean) {
        mongoQuery = mongoQuery.lean();
      }

      // Allow disk use for large datasets
      if (allowDiskUse) {
        mongoQuery = mongoQuery.allowDiskUse(true);
      }

      // Execute queries in parallel
      const [data, total] = await Promise.all([
        mongoQuery.exec(),
        model.countDocuments(query)
      ]);

      const totalPages = Math.ceil(total / sanitizedLimit);
      const hasNextPage = sanitizedPage < totalPages;
      const hasPrevPage = sanitizedPage > 1;

      const result = {
        data,
        pagination: {
          page: sanitizedPage,
          limit: sanitizedLimit,
          total,
          pages: totalPages,
          hasNextPage,
          hasPrevPage,
          nextPage: hasNextPage ? sanitizedPage + 1 : null,
          prevPage: hasPrevPage ? sanitizedPage - 1 : null
        }
      };

      structuredLogger.logInfo('PAGINATION_SUCCESS', {
        model: model.modelName,
        page: sanitizedPage,
        limit: sanitizedLimit,
        total,
        totalPages,
        queryKeys: Object.keys(query)
      });

      return result;
    } catch (error) {
      structuredLogger.logError('PAGINATION_FAILED', {
        error: error.message,
        model: model?.modelName,
        query,
        options
      });
      throw error;
    }
  }

  /**
   * Paginate with aggregation pipeline
   * @param {Object} model - Mongoose model
   * @param {Array} pipeline - Aggregation pipeline
   * @param {Object} options - Pagination options
   * @returns {Promise<Object>} Paginated result
   */
  async paginateAggregate(model, pipeline = [], options = {}) {
    try {
      const {
        page = 1,
        limit = this.defaultLimit,
        sort = this.defaultSort,
        allowDiskUse = false
      } = options;

      const sanitizedPage = Math.max(1, parseInt(page));
      const sanitizedLimit = Math.min(this.maxLimit, Math.max(1, parseInt(limit)));
      const skip = (sanitizedPage - 1) * sanitizedLimit;

      // Add sorting to pipeline
      if (sort) {
        pipeline.push({ $sort: this.parseSort(sort) });
      }

      // Add pagination to pipeline
      pipeline.push(
        { $skip: skip },
        { $limit: sanitizedLimit }
      );

      // Count total documents (before pagination)
      const countPipeline = pipeline.slice(0, -2); // Remove skip and limit
      countPipeline.push({ $count: 'total' });

      // Execute aggregation
      const [data, countResult] = await Promise.all([
        model.aggregate(pipeline, { allowDiskUse }),
        model.aggregate(countPipeline, { allowDiskUse })
      ]);

      const total = countResult[0]?.total || 0;
      const totalPages = Math.ceil(total / sanitizedLimit);
      const hasNextPage = sanitizedPage < totalPages;
      const hasPrevPage = sanitizedPage > 1;

      return {
        data,
        pagination: {
          page: sanitizedPage,
          limit: sanitizedLimit,
          total,
          pages: totalPages,
          hasNextPage,
          hasPrevPage,
          nextPage: hasNextPage ? sanitizedPage + 1 : null,
          prevPage: hasPrevPage ? sanitizedPage - 1 : null
        }
      };
    } catch (error) {
      structuredLogger.logError('PAGINATION_AGGREGATE_FAILED', {
        error: error.message,
        model: model?.modelName,
        pipeline,
        options
      });
      throw error;
    }
  }

  /**
   * Parse sort string to MongoDB sort object
   * @param {String} sort - Sort string (e.g., '-createdAt,name')
   * @returns {Object} MongoDB sort object
   */
  parseSort(sort) {
    const sortObj = {};
    
    if (typeof sort === 'string') {
      sort.split(',').forEach(field => {
        const trimmed = field.trim();
        if (trimmed.startsWith('-')) {
          sortObj[trimmed.substring(1)] = -1;
        } else {
          sortObj[trimmed] = 1;
        }
      });
    } else if (typeof sort === 'object') {
      return sort;
    }

    return sortObj;
  }

  /**
   * Create pagination metadata for API responses
   * @param {Object} pagination - Pagination object
   * @param {String} baseUrl - Base URL for links
   * @param {Object} query - Query parameters
   * @returns {Object} Pagination metadata with links
   */
  createPaginationMeta(pagination, baseUrl, query = {}) {
    const { page, pages, hasNextPage, hasPrevPage, nextPage, prevPage } = pagination;
    
    const createUrl = (pageNum) => {
      const url = new URL(baseUrl);
      Object.keys(query).forEach(key => {
        if (key !== 'page') {
          url.searchParams.set(key, query[key]);
        }
      });
      url.searchParams.set('page', pageNum);
      return url.toString();
    };

    return {
      ...pagination,
      links: {
        first: createUrl(1),
        last: createUrl(pages),
        next: hasNextPage ? createUrl(nextPage) : null,
        prev: hasPrevPage ? createUrl(prevPage) : null,
        self: createUrl(page)
      }
    };
  }

  /**
   * Validate pagination parameters
   * @param {Object} params - Request parameters
   * @returns {Object} Validated parameters
   */
  validateParams(params) {
    const { page, limit, sort } = params;
    
    const validated = {
      page: Math.max(1, parseInt(page) || 1),
      limit: Math.min(this.maxLimit, Math.max(1, parseInt(limit) || this.defaultLimit)),
      sort: sort || this.defaultSort
    };

    return validated;
  }

  /**
   * Create cursor-based pagination for real-time data
   * @param {Object} model - Mongoose model
   * @param {Object} query - MongoDB query
   * @param {Object} options - Cursor options
   * @returns {Promise<Object>} Cursor paginated result
   */
  async paginateCursor(model, query = {}, options = {}) {
    try {
      const {
        cursor,
        limit = this.defaultLimit,
        sort = this.defaultSort,
        select = '',
        populate = ''
      } = options;

      const sanitizedLimit = Math.min(this.maxLimit, Math.max(1, parseInt(limit)));

      // Add cursor condition to query
      if (cursor) {
        const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
        const sortOrder = sort.startsWith('-') ? -1 : 1;
        
        if (sortOrder === -1) {
          query[sortField] = { $lt: cursor };
        } else {
          query[sortField] = { $gt: cursor };
        }
      }

      let mongoQuery = model.find(query);

      if (select) mongoQuery = mongoQuery.select(select);
      if (populate) mongoQuery = mongoQuery.populate(populate);
      if (sort) mongoQuery = mongoQuery.sort(sort);

      mongoQuery = mongoQuery.limit(sanitizedLimit + 1).lean();

      const data = await mongoQuery.exec();
      const hasNextPage = data.length > sanitizedLimit;
      
      if (hasNextPage) {
        data.pop(); // Remove extra item
      }

      const nextCursor = hasNextPage && data.length > 0 
        ? data[data.length - 1][sort.startsWith('-') ? sort.substring(1) : sort]
        : null;

      return {
        data,
        pagination: {
          limit: sanitizedLimit,
          hasNextPage,
          nextCursor,
          count: data.length
        }
      };
    } catch (error) {
      structuredLogger.logError('CURSOR_PAGINATION_FAILED', {
        error: error.message,
        model: model?.modelName,
        query,
        options
      });
      throw error;
    }
  }
}

module.exports = new PaginationService();
