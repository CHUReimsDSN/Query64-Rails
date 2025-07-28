module Query64

  def self.permit_metadata_params(params)
    params.permit(
      query64Params: [
        :resourceName,
        context: {}
      ]
    )
  end

  def self.permit_row_params(params)
    params.permit(
      query64Params: [
        :resourceName,
        :shallReturnCount,
        context: {},
        columnsToDisplay: [],
        agGridServerParams: [
          :startRow,
          :endRow,
          :pivotMode,
          groupKeys: [],
          rowGroupCols: [
            :id,
            :displayName,
            :field,
          ],
          valueCols: [
            :id,
            :displayName,
            :field,
          ],
          pivotCols: [
            :id,
            :displayName,
            :field,
          ],
          sortModel: [
            :sort,
            :colId
          ],
          filterModel: {}
        ]
      ]
  )
  end
end